clc;
close all;
clear all;

%% data extraction
N_x = 20; % sampling number in x-axis
N_y = 21; % sampling number in y-axis
N_Tx = 3;
N_Rx = 4;
N_fast = 256;
N_slow = 128;
N_frames = 8; 

raw_data = zeros(N_fast, N_slow, N_Rx*N_Tx, N_frames, N_y, N_x);
for i = 1: N_y
    fileNum = num2str(i, '%01d');
    fileprefix = 'adc_row';
    filename = [fileprefix fileNum];
    load(filename);
    for j = 1:N_x
        raw_data(:,:,:,:,i,j) = recorded_data{j}(:,:,:,:);
    end
end
% [256 128 12 8 21 20]
disp(['size of data cube: ', num2str(size(raw_data))]);

%% datacube formation
data_cube = zeros(N_fast, N_y, N_x);
data_cube = squeeze(sum(raw_data(:,:,1,1,:,:),2));
save('data_cube');
