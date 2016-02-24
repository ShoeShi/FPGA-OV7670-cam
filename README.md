# FPGA-OV7670-cam

This is a Branch for a working implementation for the Altera Cyclone III DE0 (As the old board has been returned to its rightful owner).

Please check the other branch(with more features) for CycloneII. The "master" is currently with the board that is most available to me.

=============================
Notable changes 2/24/16
=============================
- Audio component removed for new board III, as this board has no audio


=============================
Summary
=============================

Camera + Add-on, using OV7670 FPGA Cyclone III

This is a surveillance camera implementation side project for OV7670 using an FPGA, based on the implementation in Hamster Wiki OV7670. The very underlying fundamentals is credited to this implementation.  

![cam](/../screenshot/scrn/cam.jpg?raw=true "cam")

Though structurally similar, they work on two entirely different systems. For this, I use 80x60 frame and displayed using VGA, stretched, and the timings are different. This is due to the RAM available on the hardware. 

Using 3.3v supply, the camera works but colour is a bit distorted. It is strongly recommended to use a maximum of 3Vs.

There is currently a surveillance camera second mode add-on being worked on for this project as well. For now, the status of this add-on is only partially implemented. 


All of the code in progress is provided, but will only work for a similar system using Quartus.

=============================
Modes
=============================

Normal capture mode:
	30fps, 12bit RGB, 80x60
Surv mode, example:
	30fps, 12bit RGB, Top half plays normally, bottom half saved frame.
Surv mode, display motion:
	30fps, 12bit RGB, 
	Top half EVEN: displays whats playing
	Top half ODD: displays the saved frame
	Bottom half: displays the saved frame
	Green pixels: Displays motion (Buggy due to Gamma)
	
=============================
Features
=============================
Sound:
 Left motion: High pitched sound
 Right motion: Low pitched sound
 Center: Gurgle sound.

Video:
 3 different modes, 6 different options for those 3 modes.

LEDS/Switches/KEYS/
 LEDG<OddNumbers>: Show Key pressed
 LEDG0 flashing: once per second.
 LEDG4: Registers finished loading 

 KEY0: Adjust motion threshold for buzzer(Debug)
 KEY1: Adjust motion threshold for buzzer(Debug2)
 KEY2: Resend registers
 KEY3: Reset MAX for LEDDisplay

 LED Display:  Displays the maximum motion of pixels (for debugging).
 
 SW0 : Colour mode (RGB, YCbCr)
 SW1 : 30/60 FPS
 SW2 -> SW4 : Colour matrix test
 SW5 : Adjust speed of motion detector
 SW6 : Freeze the capture
 SW7 : Surv mode, display motion
 SW8 : Surv mode, example
 SW9 : Normal capture mode.
 
 
 This implementation uses 4800 address blocks. 16bits per block (to store colour), due to hardware.
	Camera SCCB protocol has only write. Read is also implemented but whether it works is questionable. I was able to test the writes by changing colourmodes and clocks and observing effects.
	
	The datasheet denotes most of the way to capture bytes. Each byte takes 4 cycles to capture, and write the byte to frame buffer. PCLK is implied = SYSCLK unless it has been prescaled by registers, though not stated in datasheet. 30fps is implied at 24-25mhz clock.
	There are several combinations that could be made with the "surveillance mode options" , this also means there's a ton of extra code involved with it.
	
	The motion detector works by addressing pixel 1 from top half, saved to temp storage, retreive pixel 1 from bottom half, compare.
	There are two thresholds for the motion detector, one for green pixels, and one for counting the number of green pixels (buzzer).
		
	The SRAM from the board is dual-port and is restrained to simultaneous 1 read, 1 write. or 2 reads. or 2 writes.
	With the camera constantly writing frames, I am only allowed 1 read in the VGA component, therefore only this method can be used at the moment. The good news is, this saves a lot of memory, with the cost of lowering our resolution to 80 x 30.
	I chose 80 x 30, because wide is a lot better for detecting left vs right.
	
Original goal for this project was simply displaying captured data. So I am pretty happy with how far this is gotten. VHDL, Verilog, GPIO installation via cable, and other stuff learnt in a short time period.