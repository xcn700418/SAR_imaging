clc;clear all; close all;
% Create a serial object
s = serialport("COM9", 115200); % Replace "COM1" with the appropriate serial port
% write message
pause(2);
msg = 'mm+1\n';
n_sampling = 100; % number of datasets for one height level
%LF---\n CR---\r
configureTerminator(s, "LF"); % Set the line terminator to LF (line feed)


%Build connection from MATLAB to mmWave studio
% Initialize mmWaveStudio .NET connection
addpath(genpath('.\'))
RSTD_DLL_Path = 'C:\ti\mmwave_studio_02_01_01_00\mmWaveStudio\Clients\RtttNetClientController\RtttNetClientAPI.dll';

ErrStatus = Init_RSTD_Connection(RSTD_DLL_Path);
if (ErrStatus ~= 30000)
    disp('Error inside Init_RSTD_Connection');
    return;
end
% Load radar configurations
strFilename = 'C:\\ti\\mmwave_studio_02_01_01_00\\mmWaveStudio\\Scripts\\Cascade\\Cascade_Configuration_MIMO.lua';
Lua_String = sprintf('dofile("%s")',strFilename);
ErrStatus =RtttNetClientAPI.RtttNetClient.SendCommand(Lua_String);

% load capture Lua scripts
strFilename2 = 'C:\\ti\\mmwave_studio_02_01_01_00\\mmWaveStudio\\Scripts\\Cascade\\Cascade_Capture.lua';
Lua_String2 = sprintf('dofile("%s")',strFilename2);

% Collect data for n_sampling times
for i = 1:n_sampling
    ErrStatus =RtttNetClientAPI.RtttNetClient.SendCommand(Lua_String2);
    writeline(s,msg);
    message = readline(s); % Read the message
    disp(message); % Display the message
    pause(1);
end