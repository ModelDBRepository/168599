% Code written by Claudia Clopath, Imperial College London
% Please cite Tatjana Tchumatchenko* and Claudia Clopath*
% "Oscillations emerging from noise-driven steady state in networks
% with electrical synapses and subthreshold resonance"
% Nature Communications, 2014

clear all
% Defining network model parameters
vtE = 10;                   % Spiking threshold for excitatory neurons [mV]
vtI = 4;                    % Spiking threshold for inhibitory neurons [mV]
tau_vI = 10;                % Membrane capacitance for inhibitory neurons [pf]
tau_vE = 40;                % Membrane capacitance for excitatory neurons [pf]
tau_ad = 20;                % Time constant of inhibitory adaption variable [ms]
TsigI = 10;                 % Variance of current in the inhibitory neurons
TsigE = 12;                 % Variance of current in the excitatory neurons
tau_I = 10;                 % Time constant to filter the synaptic inputs [ms]
beta_adE = 0;               % No adaptation in the excitatory neurons
beta_adI = 4.5;             % Conductance of the adaptation variable variable of inhibitory neurons
alpha_adI = -2;             % Coupling of the adaptation variable variable of inhibitory neurons
alpha_adE = 0;              % No adaptation in the excitatory
GammaII = 15;               % I to I connectivity
GammaIE = -10;              % I to E connectivity
GammaEE = 15;               % E to E connectivity
GammaEI =15;                % E to I connectivity
TEmean = 0.5*vtE;           % Mean current to excitatory neurons

% Simulation parameters
N = 5000;                   % Number of neurons in total
NE = 0.8*N;                 % Number of excitatory neurons
NI = 0.2*N;                 % Number of inhibitory neurons
dt = 0.01;                  % Simulation time bin [ms]
T = 600/dt;                 % Simulation length [ms]

% If simulations with the aEIF neuron model
Delta_T = 0.5;              % exponential parameter
refrac = 5/dt;              % refractory period [ms]
ref= refrac*zeros(N,1);     % refractory counter


% Simulating two sets of parameters
for condition =1:2
    if condition ==1 % Asynchronous irregular parameters
        gamma_c = 0.1;              % subthreshold gap-junction parameter
        TImean = -5*vtI;            % mean input current in inhibitory neurons
    end
    if condition ==2 % Oscillatory regime
        gamma_c =0.9;               % subthreshold gap-junction parameter
        TImean = 1*vtI;             % mean input current in inhibitory neurons
    end
    
    %Calculation of effective simulation parameters
    g_m = 1;                            % effective neuron conductance
    Gama_c = g_m*gamma_c/(1-gamma_c);
    c_mI = tau_vI*(g_m+Gama_c);         % effective neuron time constant
    alpha_wI = alpha_adI*(g_m+Gama_c);  % effective adaption coupling
    c_mE = tau_vE*g_m;
    alpha_wE = alpha_adE*g_m;
    NEmean = TEmean*g_m;
    NImean = TImean*(g_m+Gama_c);       % effective mean input current
    NEsig = TsigE*g_m;
    NIsig = TsigI*(g_m+Gama_c);         % effective variance of the input current
    Vgap = Gama_c/NI;                   % effective gap-junction subthreshold parameter
    WII = GammaII*c_mI/NI/dt;           % effective I to I coupling
    WEE = GammaEE*c_mE/NE/dt;           % effective E to E coupling
    WEI = GammaEI*c_mI/NE/dt;           % effective E to I coupling
    WIE = GammaIE*c_mE/NI/dt;           % effective I to E coupling
    
    % Initialization
    v = 0*ones(N,1);
    c_m = zeros(N,1);
    c_m(1:NE) = c_mE;
    c_m(NE+1:end) = c_mI;
    alpha_w = zeros(N,1);
    alpha_w(1:NE) = alpha_wE;
    alpha_w(NE+1:end) = alpha_wI;
    vt = zeros(N,1);
    vt(1:NE) = vtE;
    vt(NE+1:end) = vtI;
    beta_ad = zeros(N,1);
    beta_ad(1:NE) = beta_adE;
    beta_ad(NE+1:end) = beta_adI;
    vm1 = 0*ones(N,1);
    ad = zeros*ones(N,1);
    vv = zeros(N,1);
    Iback = zeros(N,1);
    Im_sp = 0;
    Igap = zeros(N,1);
    Ichem = zeros(N,1);
    Ieff = zeros(N,1);
    
    % time lool
    Iraster = [];                                                       % save spike times for plotting
    for t = 1:T
        Iback = Iback + dt/tau_I*(-Iback +randn(N,1));                  % generate a colored noise for the current
        Ieff(1:NE) = Iback(1:NE)/sqrt(1/(2*(tau_I/dt)))*NEsig+NEmean;   % rescaling the noise current to have the correct mean and variance
        Ieff(NE+1:end) = Iback(NE+1:end)/sqrt(1/(2*(tau_I/dt)))*NIsig+NImean; % rescaling for inhibitory neurons
        Ichem(1:NE) = Ichem(1:NE) + dt/tau_I*(-Ichem(1:NE) + WEE*(sum(vv(1:NE))-vv(1:NE))+WIE*(sum(vv(NE+1:end)))); % current coming from the chemical synapses
        Ichem(NE+1:end) = Ichem(NE+1:end) + dt/tau_I*(-Ichem(NE+1:end) +WII*(sum(vv(NE+1:end))-vv(NE+1:end))+WEI*(sum(vv(1:NE))));
        Igap(NE+1:end) = Vgap*(sum(v(NE+1:end))-NI*v(NE+1:end));    % current coming from the subthreshold gap-junction part
        %%% Simulations of the network with adaptive threshold neuron model
        v= v+ dt./c_m.*(-g_m*v +alpha_w.*ad +Ieff+Ichem+Igap);      % adaptive threshold neuron model
        ad = ad + dt/tau_ad*(-ad+beta_ad.*v);                       % adaptation variable
        vv =(v>=vt).*(vm1<vt);                                      % spike if voltage crosses the threshold from below
        vm1 = v;
        %%%
        % % If you want to simulate the network with aEIF neurons instead, comment
        % % the 4 lines above and uncomments the lines below.
        % v= v+ (ref>refrac).*(dt./c_m.*(-g_m*v+ g_m*Delta_T*exp((v-vt)/Delta_T) +alpha_w.*ad +Ieff+Ichem+Igap));% aEIF neuron model
        % ad = ad + (ref>refrac).*(dt/tau_ad*(-ad+beta_ad.*v));% adaptation variable
        % vv =(v>=vt);% spike if voltage crosses the threshold
        % ref = ref.*(1-vv)+1; % update of the refractory period
        % ad = ad+vv*(30); % spike-triggered adaptation
        % v = (v<vt).*v; % reset after spike
        Isp = find(vv(NE+1:end));                                   % save spike times for plotting
        Iraster=[Iraster;t*ones(length(Isp),1),Isp];                % save spike times for plotting
    end
    
    % Plot
    h = figure; hold on;
    plot(Iraster(:,1)*dt, Iraster(:,2),'.')
    xlim([500 600])
    xlabel('time [ms]','fontsize',20)
    ylabel('I neuron index','fontsize',20)
    set(gca,'fontsize',20);
    set(gca,'YDir','normal')
end 