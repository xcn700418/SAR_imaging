addpath(genpath('.\'))

% Initialize mmWaveStudio .NET connection
RSTD_DLL_Path = 'C:\ti\mmwave_studio_02_01_01_00\mmWaveStudio\Clients\RtttNetClientController\RtttNetClientAPI.dll';

ErrStatus = Init_RSTD_Connection(RSTD_DLL_Path);
if (ErrStatus ~= 30000)
    disp('Error inside Init_RSTD_Connection');
    return;
end

% Load radar configurations
%{
strFilename = 'C:\\ti\\mmwave_studio_02_01_01_00\\mmWaveStudio\\Scripts\\Cascade\\Cascade_Configuration_MIMO.lua';
Lua_String = sprintf('dofile("%s")',strFilename);
ErrStatus =RtttNetClientAPI.RtttNetClient.SendCommand(Lua_String);
%}

strFilename2 = 'C:\\ti\\mmwave_studio_02_01_01_00\\mmWaveStudio\\Scripts\\Cascade\\Cascade_Capture.lua';
Lua_String2 = sprintf('dofile("%s")',strFilename2);
%ErrStatus =RtttNetClientAPI.RtttNetClient.SendCommand(Lua_String2);
