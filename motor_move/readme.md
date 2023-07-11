##
motor.ino includes the code to control the Arduino mega2560 and motor.  
The slider on the electric rail (the 'black box' in the figure below) driven by the stepper motor can move in certain distance, so that make the radar sensor move horizontally.  
Type mm+X to move the slider in right direction with distance of X
Type mm+Xr to move the slider in right direction with distance of X and repeat this process for 'total\_sampling' times.  

2023.0711 update  
The commands(i.e. mm+1, etc) does not need to be typed in by using serial monitor, it can be used in conjunction with the matlab file 'read_serial.m' to control the stepper motor.  
![Image text](https://github.com/xcn700418/SAR_imaging/blob/main/img/electric_rail.jpg)
