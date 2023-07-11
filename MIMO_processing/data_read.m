% read binary files
clc;close all; clear all;
N_files = 71;
recorded_data = cell(1, N_files);
DirName = 'C:\ti\mmwave_studio_02_01_01_00\mmWaveStudio\PostProc\0711\';
fileStart = 'master_';
fileEnd = '_data.bin';
N_Tx = 3;
N_Rx = 4;
N_fast = 256;
N_slow = 64;
N_frames = 8;
chunkSize = N_Tx*N_Rx*N_fast*N_slow*2;
for fileNameIdx = 1:N_files
    Idx = fileNameIdx-1;
    fileNum = num2str(Idx, '%01d');
    if Idx < 10
        cfileNum = ['000' fileNum];
    elseif (Idx < 100) && (Idx >= 10)
        cfileNum = ['00' fileNum];
    else
        cfileNum = ['0' fileNum];
    end

    fileName = [fileStart cfileNum fileEnd];

 

    fname = strcat(DirName,fileName);

    fid = fopen(fname,'r');


    [input_data, num_cnt] = fread(fid,Inf,'int16');


    expected_num_samples = (N_Tx * N_Rx* N_fast * N_slow * N_frames);


     disp(['Number of expected ADC samples: ',num2str(expected_num_samples)]);

     disp(['Number of ADC samples read:     ',num2str(num_cnt)]);

%     

 

    adcOut = [];

    inputLoadingPosition = 0;


    fullData = zeros(N_fast, N_slow, N_Rx*N_Tx, N_frames);

    for indexFrames=1:N_frames


        fseek(fid, inputLoadingPosition, 'bof');

        dataChunk  = fread(fid, chunkSize,'uint16','l');

        inputLoadingPosition = ftell(fid);   


        dataChunk = dataChunk - (dataChunk >= 2^15) * 2^16;


        % radar_data has data in the following format.

        % Rx0I0, Rx0I1, Rx0Q0, Rx0Q1, Rx0I2, Rx0I3, Rx0Q2, Rx0Q3, ...

        % The following script reshapes it into a 3-dimensional array.

        % size(adcOut) = [ADC samples per chirp x Chirps per Frame x Number of virtual Channels]


        len = length(dataChunk) / 2;

        adcOut(1:2:len) = dataChunk(1:4:end) + 1j*dataChunk(3:4:end);

        adcOut(2:2:len) = dataChunk(2:4:end) + 1j*dataChunk(4:4:end);

        adcOut = reshape(adcOut, [N_fast, N_Rx*N_Tx, N_slow]);

        adcOut = permute(adcOut, [1, 3, 2]);


        fullData(:,:,:,indexFrames) = adcOut;


    end
    
    recorded_data{fileNameIdx} = fullData;

end

%save("recorded_data");