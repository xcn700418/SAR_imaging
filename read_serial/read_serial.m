% Create a serial object
s = serialport("COM9", 115200); % Replace "COM1" with the appropriate serial port

% Set the ReadAsyncMode property to "continuous" to continuously read data
configureTerminator(s, "LF"); % Set the line terminator to LF (line feed)
s.ReadAsyncMode = "continuous";

% Read and display messages from Arduino
while true
    if s.NumBytesAvailable > 0
        message = readline(s); % Read the message
        disp(message); % Display the message
    end
end

% Cleanup
clear s;