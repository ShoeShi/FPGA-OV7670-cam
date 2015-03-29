# FPGA-OV7670-cam
Camera + Add-on using OV7670 FPGA Cyclone II - 4550

This is a surveillance camera implementation side project for OV7670 using an FPGA, based on the implementation in Hamster Wiki OV7670. The very underlying fundamentals is credited to this implementation.  


![cam](/../screenshot/scrn/cam.jpg?raw=true "cam")


Though structurally similar, they work on two entirely different systems. For this, I use 80x60 frame and displayed using VGA, stretched, and the timings are different. This is due to the RAM available on the hardware. 

Using 3.3v supply, the camera works but colour is a bit distorted. It is strongly recommended to use a maximum of 3Vs.

There is currently a surveillance camera second mode add-on being worked on for this project as well. For now, the status of this add-on is only partially implemented. 


All of the code in progress is provided, but will only work for a similar system using Quartus.
