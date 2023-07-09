%% load data
clc; close all; clear all;
load('data_cube.mat');
data_cube = data_cube(:,1:10,:);
%% define parameters
N_x = 20; % sampling number in x-axis
N_y = 10; % sampling number in y-axis
Dx = 200; % unit mm
Dy = 50; % unit mm
dx = Dx/N_x; % sampling distance interval of x-axis (mm)
dy = Dy/N_y; % sampling distance interval of y-axis (mm)

z0 = 0.5; % unit m     % Range of target (range of corresponding image slice)
N_Tx = 3;
N_Rx = 4;
N_fast = 256;
N_slow = 128;
N_frames = 8; 

nFFTtime = 1024;    % Number of FFT points for Range-FFT
nFFTspace = 1024;   % Number of FFT points for Spatial-FFT
imgSize = 200;
% fixed parameters
c = physconst('lightspeed');
fS = 10e6;        % Sampling rate (sps)
Ts = 1/fS;          % Sampling period
T = 60e-6;
K = 29.98e12;      % Slope const (Hz/sec)
tI = 4.5225e-10; % Instrument delay for range calibration (corresponds to a 6.78cm range offset)
idle = 100e-6;
f0 = 77e9; % start frequency
xPointM = 1024;
yPointM = 1024;
%% compensation


%% Range compression
% 1. range FFT
 rawDataFFT = fft(data_cube,nFFTtime);
% Range focusing to z0
k = round(K*Ts*(2*z0/c+tI)*nFFTtime); % beat frequency*fft number
sarData = squeeze(rawDataFFT(30,:,:));

%% create matched filter
x = 1e-3 * dx * ( -(xPointM-1)/2 : (xPointM-1)/2 ); % unit of x in m
y = (1e-3 * dy * (-( yPointM-1)/2 : (yPointM-1)/2 )).'; % unit of y in m
matchedFilter = exp(-1i*2*2*pi*(f0/c)*sqrt(x.^2 + y.^2 + z0^2));

%% check dimension of SAR data and matched filter
[yPointS,xPointS] = size(sarData);
[yPointF,xPointF] = size(matchedFilter);
%% dimension equalization using Zero Padding
if (xPointF > xPointS)
    sarData = padarray(sarData,[0 floor((xPointF-xPointS)/2)],0,'pre');
    sarData = padarray(sarData,[0 ceil((xPointF-xPointS)/2)],0,'post');
else  
    matchedFilter = padarray(matchedFilter,[0 floor((xPointS-xPointF)/2)],0,'pre');
    matchedFilter = padarray(matchedFilter,[0 ceil((xPointS-xPointF)/2)],0,'post');
end

if (yPointF > yPointS)
    sarData = padarray(sarData,[floor((yPointF-yPointS)/2) 0],0,'pre');
    sarData = padarray(sarData,[ceil((yPointF-yPointS)/2) 0],0,'post');
else  
    matchedFilter = padarray(matchedFilter,[floor((yPointS-yPointF)/2) 0],0,'pre');
    matchedFilter = padarray(matchedFilter,[ceil((yPointS-yPointF)/2) 0],0,'post');
end
%% Create SAR Image
sarDataFFT = fft2(sarData);
matchedFilterFFT = fft2(matchedFilter);
sarImage = fftshift(ifft2(sarDataFFT .* matchedFilterFFT));

%% Define Target Axis
[yPointT,xPointT] = size(sarImage);

xRangeT = dx * (-(xPointT-1)/2 : (xPointT-1)/2); % xStepM is in mm
yRangeT = dy * (-(yPointT-1)/2 : (yPointT-1)/2); % yStepM is in mm
%% Crop the Image for Related Region
indXpartT = xRangeT>(-imgSize/2) & xRangeT<(imgSize/2);
indYpartT = yRangeT>(-imgSize/2) & yRangeT<(imgSize/2);

xRangeT = xRangeT(indXpartT);
yRangeT = yRangeT(indYpartT);
sarImage = sarImage(indYpartT,indXpartT);

%% Plot SAR Image
figure; mesh(xRangeT,yRangeT,abs(fliplr(sarImage)),'FaceColor','interp','LineStyle','none')
view(2)
colormap('jet');

xlabel('Horizontal (mm)')
ylabel('Vertical (mm)')
titleFigure = "SAR Image - Matched Filter Response";
title(titleFigure)



