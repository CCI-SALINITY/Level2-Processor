%Constante dielectrique BV
% obtenu avec sigSST = 0.6°C (pour la correction de biais sur Acard)

function epsr=epsr_BV(sst_in,s)

% input: 
%   sst_in : SST in °C
%   s      : SSS in pss
% output:
%   epsr   : diel cste (complex number)
% authors  : ACRI-ST/LOCEAN, 2019



freq=1.41350;  % GHz
alpha=0.00314; % Somaraju cste

f0=17.97510;

x=[5.7230e+00, 2.2379e-02, -7.1237e-04, 5.0478e+00, -7.0315e-02, 6.0059e-04, 3.6143e+00,...
    2.8841e-02, 1.3652e-01,  1.4825e-03, 2.4166e-04];

z=[-3.56417e-03,  4.74868e-06,  1.15574e-05,  2.39357e-03, -3.13530e-05, ...
    2.52477e-07, -6.28908e-03,  1.76032e-04, -9.22144e-05, -1.99723e-02, ...
    1.81176e-04, -2.04265e-03,  1.57883e-04];

sst=sst_in;

%protects against n1 and n2 going zero for very cold water
ind=find(sst<=-30.16);
sst(ind)=-30.16;

sst2=sst.*sst;
sst3=sst2.*sst;
sst4=sst3.*sst;
sst5=sst4.*sst;
sst6=sst5.*sst;

s2=s.*s;
s3=s2.*s;

%     pure water : on n'y touche pas
e0    = (3.70886e4 - 8.2168e1*sst)./(4.21854e2 + sst);      % stogryn et al. e0=epss(T,S=0), eau distilée
e1    = x(1) + x(2).*sst + x(3).*sst2;                      % eps1 (notations papier MW)
n1    = (45.00 + sst)./(x(4) + x(5).*sst + x(6).*sst2);     % nu1

%     saline water
%     conductivity [s/m] taken from stogryn et al.
sig35 = 2.903602 + 8.60700e-2.*sst + 4.738817e-4.*sst2 - 2.9910e-6.*sst3 + 4.3047e-9.*sst4;
r15   = s.*(37.5109+5.45216.*s+1.4409e-2.*s2)./(1004.75+182.283.*s+s2);
alpha0 = (6.9431+3.2841.*s-9.9486e-2.*s2)./(84.850+69.024.*s+s2);
alpha1 = 49.843 - 0.2276.*s + 0.198e-2.*s2;
rtr15 = 1.0 + (sst-15.0).*alpha0./(alpha1+sst);

sig = sig35.*r15.*rtr15;

%    permittivity
a0 = 1-s.*alpha;
e0s = a0.*e0;    % epss dans la formule de MW

PP=[0.000000004035165, -0.000000299656045, 0.000007662053700, -0.000078086884746, 0.000692115342716, -0.013677965710063, 1.029287588881387];
fSST=PP(1)*sst6 + PP(2)*sst5 + PP(3)*sst4 + PP(4)*sst3 + PP(5)*sst2 + PP(6)*sst + PP(7);

b1 = fSST;
n1s = n1.*b1;   % nu1 dans la formule de MW

%a1  = exp(z(7).*s + z(8).*s2 + z(9).*s.*sst);
a1  = 1;
e1s = e1.*a1;   % eps1 dans la formule de MW : on n'y touche pas

epsr = (e0s - e1s)./(1.0 + j.*(freq./n1s)) + e1s - j.*sig.*f0./freq;

