%% Range-doppler algorithm
clear;close all;clc;
 
%% parameter definition
% signal parameter
c = physconst("Lightspeed");
fc = 1e9;                               % carrier frequency
lambda = c/fc;                          % wavelength
 
% detection range
% Az0 and AL form the detection area with a rectangular shape
Az0 = 10e3;                             
AL = 1000;
% range of the detection area
Azmin = Az0-AL/2;                      
Azmax = Az0+AL/2;          
% ground distance between detection area and the radar sensor
Grd_R0 = 10e3;                             
Grd_RL = 1000;                             
 
% parameter for the radar platform
vr = 100;                               % speed of radar platform
height = 3000;                               % height of the radar
% slant range : range between radar and the center of detection area
R0 = sqrt(Grd_R0^2+height^2);                   
 
% Antenna parameter
D = 4;                                  % antenna size
% according to synthetic beam width βs = λ /(2* La) = D / (2* R)
La = lambda*R0/D;                       % synthetic aperture length ???
Ta = La/vr;                             % synthetic aperture time
 
% azimuth and velocity dimension parameter
Ka = -2*vr^2/lambda/R0;                 % frequency-modulated rate
Ba = abs(Ka*Ta);                        % bandwidth
PRF = 1.2*Ba;                           % pulse repetition frequency
Nslow = ceil((Azmax-Azmin+La)/vr*PRF);  % number of chirp
Nslow = 2^nextpow2(Nslow);              % velocity fft point 
ta = linspace((Azmin-La/2)/vr,(Azmax+La/2)/vr,Nslow);  % slow time axis
PRF = 1/((Azmax-Azmin+La)/vr/Nslow);    % pulse repetition frequency
 
% range dimension/fast time parameter
Tw = 5e-6;                              % time for one chirp
Br = 30e6;                              % bandwidth
Kr = Br/Tw;                             % frequency-modulated rate
Fr = 2*Br;                              % sampling rate
Rmin = sqrt((Grd_R0-Grd_RL/2)^2+height^2);
Rmax = sqrt((Grd_R0+Grd_RL/2)^2+height^2+(La/2)^2);
Nfast = ceil(2*(Rmax-Rmin)/c*Fr+Tw*Fr); % 
Nfast = 2^nextpow2(Nfast);              % range FFT point
tr = linspace(2*Rmin/c,2*Rmax/c+Tw,Nfast);% fast time axis  
Fr = 1/((2*Rmax/c+Tw-2*Rmin/c)/Nfast);  % sampling rate
 
% resolution
resD = c/(2*Br);                          % range resolution
resA = D/2;                               % azimuth resolution
 
% Create simulation point
Ntarget = 6;                            % total target point
Target_position = [Az0-50,Grd_R0-100,1              % target posititon in detection area
         Az0+50,Grd_R0-50,1
         Az0-50,Grd_R0+50,1
         Az0+50,Grd_R0+100,1
         Az0,Grd_R0,1
         Az0+200,Grd_R0+200,1];  
  
  
fprintf('Synthetic aperture size：%.1fm\n',La);     
disp('Target location /slant range：');
disp([Target_position(:,1),Target_position(:,2),sqrt(Target_position(:,2).^2+height^2)])
 
%% detection area discretization (both range and azimuth)
deltaR = c/(Fr*2);
R = Rmin:deltaR:Rmax;  % slant range axis
Nr = length(R);

deltaA = vr/PRF;
Az = Azmin:deltaA:Azmax; % azimuth axis
Na = length(Az);
 
%% Reflected signal model
snr = zeros(Nslow,Nfast); 

for k = 1:1:Ntarget
    ref_coefficient = Target_position(k,3);
    Azk = ta*vr-Target_position(k,1);             %Ra(t)
    Rk = sqrt(Azk.^2+Target_position(k,2)^2+height^2); %R(t)
    tauk = 2*Rk/c;
    tk = ones(Nslow,1)*tr-tauk'*ones(1,Nfast);
    phasek = pi*Kr*tk.^2-(4*pi/lambda)*(Rk'*ones(1,Nfast));
    s = ref_coefficient*exp(1i*phasek).*(0<tk&tk<Tw).*((abs(Azk)<La/2)'*ones(1,Nfast));
    snr = snr+s;
end
lb = min(find(snr(:,295)));
hb = max(find(snr(:,295)));
figure;
subplot(2,1,1);
plot(ta(lb:hb),snr(lb:hb,295),'r');
xlabel("slow time axis");
ylabel("amplitude");
title("Signal model in slow time");

lb = min(find(snr(940,:)));
hb = max(find(snr(940,:)));
subplot(2,1,2);
plot(tr(lb:hb),snr(940,lb:hb),'b');
xlabel("fast time axis");
ylabel("amplitude");
title("Signal model in fast time");
%% Range Compression
thr = tr-2*Rmin/c;
hrc = exp(1i*pi*Kr*thr.^2).*(0<thr&thr<Tw);  % match filter for range dimension
hrcf = conj(fft(hrc,Nfast,2));
%hrc = conj(hrc);
% Multiply range fft result with the match filter in frequency domain
SARr =fft(snr,Nfast,2).*(ones(Nslow,1)*hrcf);
SARr = ifft(SARr,Nfast,2);

figure;
imagesc(255-abs(SARr));                       
xlabel('Fast time');
ylabel('Slow time');
title('Pulse compression in range dimension');
colormap(gray);

figure;
Sta = round(Ta/2*PRF);
imagesc(R,Az,255-abs(SARr(Sta:Sta+Na-1,1:Nr)));                       
xlabel('\rightarrow\itSlant range/m');
ylabel('\itAzimuth/m\leftarrow');
title('Pulse compression in range dimension');
colormap(gray);

figure;
col = round(linspace(1,Na,7));
row =round(Nr/2)-200:round(Nr/2)+200;
waterfall(R(row),Az(col),abs(SARr(col+Sta-1,row)));
xlabel('Slant range/m');
ylabel('Azimuth/m');
title('Range Compression results from different azimuth');
colormap(gray);
%% Azimuth compression 
tha = ta-Azmin/vr;
hac = exp(1i*pi*Ka*tha.^2).*(abs(tha)<Ta/2);  % Match filter in azimtuh direction
hacf = fft(hac, Nslow);
SARra = ifft(fft(SARr).*(conj(hacf).'*ones(1,Nfast)));
SAR = abs(SARra);
 
figure;
imagesc(255-SAR);                       
xlabel('fast time');
ylabel('slow time');
title('fast-slow time pulse compression');
colormap(gray)
 
figure;
mesh(R,Az,SAR(1:Na,1:Nr));
xlabel('Slant range');
ylabel('Azimuth');
title('Sar image'),