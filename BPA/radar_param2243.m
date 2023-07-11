clc;
clear all;
close all;

c = physconst('LightSpeed');
fc = 77e9; % carrier frequency
S = 79e12;  % slope Hz/s
lambda = c/fc;  % wavelength
d = 0.5*lambda;
ramptime = 40e-6; % time for one chirp
idletime = 5e-6; 
PRI = ramptime + idletime;
onechirptime = ramptime% + idletime
B = 3159.44e6;
ADCsamplingrate = 8e6; % mmWavestudio-RampTimingCal
IF_B = 0.9*ADCsamplingrate;
N_slow = 64;
N_fast = 256;

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

% snapshot data cube formation
snapshot = 16; % number of chirps selected from 1 frame to form the RVA data cube
n_sc = N_slow/snapshot;

save('AWR2243.mat')