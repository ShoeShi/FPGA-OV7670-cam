Project: Low Cost Surveillance camera
Name: Johnny Xie 7694754
Due Date: 4.1.15
I've uploaded this to my Github. It has similar readme and stuff.

=============================
Requirements
=============================
	Quartus II
	FPGA cyclone II
	OV7670 camera
	Ribbon cable

Instructions
1. Install OV7670 Camera to the Altera Cyclone II via GPIO.
2. Set the PIN configurations.
3. Open project file. Compile and program via JTAG.
On other boards:
	Frame buffers and audio must be referred to by their datasheets.

If you change settings SW5 -> SW0, you must resend registers for the changes to apply.
(KEY2)

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

Cheatsheet
- Uses 3.3v supply (2.5-3v reccommended)
- VGA outputs 80x60 frame, strechted
- Display on screen 30 FPS available/ 60FPS available in full red
- Displays in full colour 12-bit RGB. Camera displays distorted colours because of votage supply.
- Colour settings can be adjusted via matrix
- The camera itself provides auto UV focus and Gamma settings.
- Freeze frame available for all 3 modes.
- Adjusted frame freezes
- Left / Right motion detection
- Buzzer

Stats
- 1 272/ 18 752 logic elements used
- 577 Registers used
- 98 / 315 Pins used
- 102 400 / 239/616 RAMBits used

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
Description and Algorithm
=============================
	Structure:
    Top -> framebuffer, vgadriver, audiodriver, cameradriver, cameracapture
    cameradriver -> registers, sccb(i2c), buttondebounce
	
	Implementation:
	Set-up camera->Capture data->Write Framebuffer->VGA reads buffer->Process
	
	This implementation uses 4800 address blocks. 16bits per block (to store colour). 
	Reason: Pleb board doesn't support 8bit per block + higher resolution without hindering missing pixels, because of the address space.
	Second reason: 60 * 80 resolution is a factor of 8 from 640*480. I take advantage of that by using an address space that is 3 bits away from that when displaying 640*480 60hz vga. This lets me stretch vga output, instead of clipping it.
	Camera SCCB protocol has only write. Read is also implemented but whether it works is questionable. I was able to test the writes by changing colourmodes and clocks and observing effects.
	The SCCB protocol involves two lines, so it is similar to I2C. It receives the "go" and register info from registers.vhd until the registers have cycled to completion. There is a resend button if things go amiss. The datasheet goes into specific details on the protocol.
	The sysclk for OV takes 25mhz instead of the reccommended 24mhz. This causes some glitches on startup sometimes. Just resend register(KEY2) if that happens
	The capture with LASTHREF denotes the number of cycles to wait between a write. The duty cycle is a mutiple of LASTHREF ( They converge on '10' we)
	A byte is captured at every rising edge of href.
	The datasheet denotes most of the way to capture bytes. Each byte takes 4 cycles to capture, and write the byte to frame buffer. PCLK is implied = SYSCLK unless it has been prescaled by registers, though not stated in datasheet. 30fps is implied at 24-25mhz clock.
	There are several combinations that could be made with the "surveillance mode options" , this also means there's a ton of extra code involved with it.
	
	The motion detector works by addressing pixel 1 from top half, saved to temp storage, retreive pixel 1 from bottom half, compare.
		There are two thresholds for the motion detector, one for green pixels, and one for counting the number of green pixels (buzzer).
	The SRAM is restrained to simultaneous 1 read, 1 write. or 2 reads. or 2 writes.
	With the camera constantly writing frames, I am only allowed 1 read in the VGA component, therefore only this method can be used at the moment. The good news is, this saves a lot of memory, with the cost of lowering our resolution to 80 x 30.
		I chose 80 x 30, because wide is a lot better for detecting left vs right.
	My first implementation involved a sliding window. It was buggy and expensive, so now it counts the pixels that pass a threshold ( signified by green ).
	The green pixels, and motion detector become buggy during high contrast areas. Areas with lots of light or lots of dark (Its not as grim as it sounds though). This is due to the UV correction and can be adjusted by the gamma settings and threshold. Since this is location specific, I've left it to what was convienient for me at the time.

	
	Original goal for this project was simply displaying captured data. So I am pretty happy with how far this is gotten. VHDL, Verilog, GPIO installation via cable, and other stuff learnt in a short time period.

-- Future Prospects: 1. Save frame to SD Card. 
-- 2. PWM a DC motor to turn camera via left/right detection.
-- 3. Cleanup TOP.vhd 

	
I do not take ownership of Wizard-generated files + partial from audio file that was minimally modified, translated from verilog to vhdl, from the cyclone_ii starter kit.
