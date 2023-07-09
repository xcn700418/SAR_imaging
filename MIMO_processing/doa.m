%% load the data
clc;
clear;
close all;
load("recorded_data.mat");

%% fixed parameters
% signal parameters
c = physconst('LightSpeed');
fc = 77e9;
S = 29.982e12;  % Hz/s
lambda = c/fc;
ramptime = 60e-6;
idletime = 100e-6;
PRI = ramptime + idletime;
B = 4e9;
ADCsamplingrate = 5e6; % mmWavestudio-RampTimingCal
IF_B = 0.9*ADCsamplingrate;
onechirptime = ramptime% + idletime
numCPI = 8;

% max value, resolution and axis for range, velocity and angle.
dR = c/(2*B);
Rmax = (c*IF_B)/(2*S);
dV = lambda/(2*N_slow*PRI);
Vmax = 10;
range_axis = linspace(0,Rmax, N_fast); 
vel_axis = linspace(-Vmax, Vmax, N_slow); 
ang_axis = -90:90; % angle axis

% fft parameters
N_range = 256;
N_doppler = 128;
N_angle = length(ang_axis);


choose_data = 1;    % can be MODIFIED
rawdata = recorded_data{choose_data}; % [N_fast, N_slow, TX*RX, numFrame]
%% Present the data
colors = ['r', 'g', 'b', 'c', 'm', 'y', 'k', 'r', 'g', 'b', 'c', 'm']; 
figure;
t = linspace(0,onechirptime, 256);
plot(t,rawdata(:,1,1,1),'b');
title('Plot of a chirps');
xlabel('Time in one chirp');
ylabel('Amplitude');

%% 2D FFT range-velocity map
RDM = zeros(N_fast, N_slow, N_Tx*N_Rx, N_frames);
RDM = fftshift(fft2(rawdata,N_range,N_doppler),2);

figure;
imagesc(vel_axis,range_axis,20*log10(abs(RDM(:,:,1,1))/max(max(abs(RDM(:,:,1,1))))));
colormap(jet(256))
colorbar;
% set(gca,'YDir','normal')
clim = get(gca,'clim');
caxis([clim(1)/2 0]);
xlabel('Velocity (m/s)');
ylabel('Range (m)');
title('range-velocity map');

%% CA-CFAR
RDM_db = 10*log10(abs(RDM(:,:,1,1))/max(max(abs(RDM(:,:,1,1)))));
numGuard = 2;
numTrain = 4;
P_fa = 1e-5;
SNR_OFFSET = -5;
[RDM_mask, cfar_ranges, cfar_dopps, num_obj] = ca_cfar(RDM_db, numGuard, numTrain, P_fa, SNR_OFFSET);

figure;
h=imagesc(vel_axis,range_axis,RDM_mask);
xlabel('Velocity (m/s)');
ylabel('Range (m)');
title('range-velocity map using CA-CFAR');

%% Angle estimation using FFT
RAC = squeeze(rawdata(:,:,:,1));
range_fft = fft(RAC,N_range);
angle_fft = fftshift(fft(range_fft,N_angle,3),3);
range_azim = squeeze(sum(angle_fft,2));

figure;
colormap(jet);
imagesc(ang_axis, range_axis, 20*log10(abs(range_azim)./max(abs(range_azim(:)))));
xlabel('Angle(degree)');
ylabel('Range(m)');
title('range-azimuth map using fft');

doa = zeros(num_obj,N_angle);
figure;
for i = 1:num_obj
    doa(i,:) = fftshift(fft(range_fft(cfar_ranges(i),cfar_dopps(i),:),N_angle));
    plot(ang_axis,10*log10(abs(doa(i,:))));
    hold on;
end
xlabel('Azimuth Angle');
ylabel('dB');

%% Angle esimation using MUSIC
d = 0.5;
% construct arrival vectors
% An arrival vector consists of the relative phase shifts at the array elements ...
% of the plane wave from one source. 
% a1 = 12*181 where 12 signal sources and 181 elements for 1 signal source.
for k=1:N_angle
        % d*(0:Tx*Rx) 为波长
        a1(:,k)=exp(-1i*2*pi*(d*(0:N_Tx*N_Rx-1)'*sin(ang_axis(k).'*pi/180)));
end
    
for i = 1:num_obj
    Rxx = zeros(N_Tx*N_Rx,N_Tx*N_Rx); % 8*8 source cov matrix
    for m = 1:numCPI
        % RDM = [numADC,numChirps,N_Tx*N_Rx,numCPI]
       A = squeeze(RDM(cfar_ranges(i),cfar_dopps(i),:,m)); % 8*1
       Rxx = Rxx + 1/numCPI * (A*A'); % estimated sensor covariance matrix.
    end

    [Q,D] = eig(Rxx); % Q: eigenvectors (columns), D: eigenvalues
    [D, I] = sort(diag(D),'descend');
    Q = Q(:,I); % Sort the eigenvectors to put signal eigenvectors first
    Qs = Q(:,1); % Get the signal eigenvectors
    Qn = Q(:,2:end); % Get the noise eigenvectors

    for k=1:N_angle
        % angle dependent power spectrum
        music_spectrum(i,k)=(a1(:,k)'*a1(:,k))/(a1(:,k)'*(Qn*Qn')*a1(:,k));
    end
end

figure; 
hold on;
grid on;
title('MUSIC Spectrum');
xlabel('Angle in degrees');
for k = 1:num_obj
    plot(ang_axis,log10(abs(music_spectrum(k,:))));
end

%% MUSIC range-azimuth map
RAC2 = fft(rawdata, N_range);

for i = 1 : N_range
    Rxx = zeros(N_Tx*N_Rx, N_Tx*N_Rx);
    for m = 1 : numCPI
        A = squeeze(sum(RAC2(i,:,:,m),2));
        Rxx = Rxx + 1/numCPI * (A*A');
    end
    [Q,D] = eig(Rxx);
    [D,I] = sort(diag(D), 'descend');
    Q = Q(:,I);
    Qs = Q(:,1);
    Qn = Q(:,2:end);

    for k=1:N_angle
        music_spectrum2(k)=(a1(:,k)'*a1(:,k))/(a1(:,k)'*(Qn*Qn')*a1(:,k));
    end
    
    range_az_music(i,:) = music_spectrum2;
end
figure
colormap(jet)
imagesc(ang_axis,range_axis,20*log10(abs(range_az_music)./max(abs(range_az_music(:))))); 
xlabel('angle in degrees')
ylabel('Range (m)')
title('MUSIC Range-Azimuth Map')
clim = get(gca,'clim');
%% CFAR-MUSIC
RDM_db2 = 10*log10(abs(range_az_music)/max(max(abs(range_az_music))));
numGuard = 2;
numTrain = 4;
P_fa = 1e-5;
SNR_OFFSET = -5;
[RDM_mask, cfar_ranges, cfar_dopps, num_obj] = ca_cfar(RDM_db2, numGuard, numTrain, P_fa, SNR_OFFSET);

figure;
h=imagesc(ang_axis,range_axis,RDM_mask);
xlabel('angle in degrees');
ylabel('Range (m)');
title('range-azimuth map using CA-CFAR and MUSIC');