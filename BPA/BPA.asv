%% load the data
clc;
clear;
close all;
load("0711_data.mat");

%% fixed parameters for radar AWR1843
load("AWR2243.mat")

rawdata = zeros(N_fast, snapshot, N_Rx*N_Tx, n_sc, N_files);

for i = 1:N_files
    tmpdata = squeeze(recorded_data{i}(:,:,:,1)); % 256*128*12,use frame 1
    for j = 1:n_sc
        data = tmpdata(:, (j-1)*snapshot+1:j*snapshot, :);
        rawdata(:,:,:,j,i) = data; 
    end
end



%% range-angle map using MUSIC/fft

RDC = recorded_data{5}(:,:,:,3); % selec 5th pos 3th frame
% [range_azim,Rxx] = MUSIC(RDC,N_fast,ang_axis,lambda); %MUSIC
range_fft = fft(RDC,N_range);
angle_fft = fftshift(fft(range_fft,N_angle,3), 3);
range_az = squeeze(sum(angle_fft,2));


figure;
imagesc(ang_axis, range_axis, abs(range_az));
xlabel('Angle(degree)');
ylabel('Range(m)');
title('range-azimuth map using fft');



%% 3D-FFT data cube
%RD_data = zeros(N_fast, snapshot,N_Rx*N_Tx, n_sc, N_files);
RD_data = fftshift(fft2(rawdata,N_range, N_doppler), 2);

RVA_data = fftshift(fft(RD_data, N_angle,3), 3);
disp(["RVA_data size ", size(RVA_data)]);
%% compensation on range bin and angle bin ~RCMC is required
figure;
subplot(2,1,1);
plot(range_axis, RD_data(:,1,1,1,1));
subplot(2,1,2);
plot(range_axis, RD_data(:,1,1,1,10));

xt = linspace(-35,35,71); % unit cm
xt = xt*0.01; % unit m
yt = 1; % unit m
dt = sqrt(xt.^2+yt^2); %relative distance between radar and target
theta_t = asin(xt./dt); %relative angle between radar and target

% range compensation
for i = 1:N_files
    for j = 1: n_sc
        for k = 1:N_angle
            for l = 1:N_doppler
                RVA_data(:,l,k,j,i) = RVA_data(:,l,k,j,i).*2*S*dt(i)/(c*ADCsamplingrate);
            end
        end
    end
end

% angle compensation
for i = 1:N_files
    for j = 1:n_sc
        for k = 1:N_doppler
            for l = 1:N_range
                RVA_data(l,k,:,j,i) = RVA_data(l,k,:,j,i).*0.5*lambda*xt(i)/(lambda*dt(i));
            end
        end
    end
end

%% choose the max intensity component for velocity bin
RVA_data = squeeze(sum(RVA_data,2));
display(["size of compensated RVA : ",size(RVA_data)])
% Match filter for phase compensation
Ht = exp(-1i*2*pi*fc*2.*dt/c);
% Resizing match filer
yPointS= size(RVA_data,1);
xPointS = size(RVA_data,2);
H = ones(yPointS,xPointS,N_files);
for i = 1:N_files
    H(:,:,i) = repmat(Ht(i),yPointS,xPointS);
end

%{
%% check dimension of SAR data and matched filter
yPointS= size(RVA_data,1);
xPointS = size(RVA_data,2);
[yPointF,xPointF] = size(Ht);
%dimension equalization using Zero Padding
if (xPointF > xPointS)
    RVA_data = padarray(RVA_data,[0 floor((xPointF-xPointS)/2)],0,'pre');
    RVA_data = padarray(RVA_data,[0 ceil((xPointF-xPointS)/2)],0,'post');
else  
    Ht = padarray(Ht,[0 floor((xPointS-xPointF)/2)],0,'pre');
    Ht = padarray(Ht,[0 ceil((xPointS-xPointF)/2)],0,'post');
end

if (yPointF > yPointS)
    RVA_data = padarray(RVA_data,[floor((yPointF-yPointS)/2) 0],0,'pre');
    RVA_data = padarray(RVA_data,[ceil((yPointF-yPointS)/2) 0],0,'post');
else  
    Ht = padarray(Ht,[floor((yPointS-yPointF)/2) 0],0,'pre');
    Ht = padarray(Ht,[ceil((yPointS-yPointF)/2) 0],0,'post');
end
%}
%% backprojection processing
image = zeros(yPointS,xPointS);
for i = 1:N_files
    for j = 1:n_sc
        image = image + H(:,:,i) .* RVA_data(:,:,j,i);
    end
end

%% plot

figure; mesh(ang_axis,range_axis,abs(image),'FaceColor','interp','LineStyle','none')
view(2)
colormap('jet');

xlabel('Horizontal (m)')
ylabel('range (m)')
titleFigure = "SAR Image(Back-projection)";
title(titleFigure)

















