----------------------------------------------------------------------------------
-- Project1_top.vhd
--
-- LEDG<OddNumbers>: Show Key pressed
-- LEDG0 flashing: once per second.
-- LEDG4: Registers finished loading 
-- Register default value check LEDG7.
-- 
-- KEY0: Debug
-- KEY1: Debug2
-- KEY2: Resend registers
--
-- SW0 : Colour mode
-- SW1 : 30/60 FPS
-- SW2 -> SW4 : Colour matrix test
--
-- The flowchart
--    Top -> buffer, vga, capture data, camera driver
--    camera driver -> settings for camera, i2c to camera to set settings
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity Project1_top is
  port (
	 CLOCK_50 : in std_logic;
	 OV7670_SIOC  : out   STD_LOGIC;
	 OV7670_SIOD  : inout STD_LOGIC;
	 OV7670_VSYNC : in    STD_LOGIC;
	 OV7670_HREF  : in    STD_LOGIC;
	 OV7670_PCLK  : in    STD_LOGIC;
	 OV7670_XCLK  : out   STD_LOGIC;
	 OV7670_D     : in    STD_LOGIC_VECTOR(7 downto 0);
	 OV7670_RESET : out   STD_LOGIC;
	 OV7670_PWDN  : out   STD_LOGIC;
	 HEX0 : out STD_LOGIC_VECTOR( 6 downto 0 );
	 HEX1 : out STD_LOGIC_VECTOR( 6 downto 0 );
	 HEX2 : out STD_LOGIC_VECTOR( 6 downto 0 );
	 HEX3 : out STD_LOGIC_VECTOR( 6 downto 0 );
	 SW : in STD_LOGIC_VECTOR( 9 downto 0 );
	 KEY : in STD_LOGIC_VECTOR( 3 downto 0);
	 VGA_R      : out   STD_LOGIC_VECTOR(3 downto 0);
	 VGA_G    : out   STD_LOGIC_VECTOR(3 downto 0);
	 VGA_B     : out   STD_LOGIC_VECTOR(3 downto 0);
	 VGA_HS    : out   STD_LOGIC;
	 VGA_VS    : out   STD_LOGIC;
	 LEDG          : out    STD_LOGIC_VECTOR(7 downto 0);
	 LEDR : out STD_LOGIC_VECTOR( 9 downto 0 )
       );
end Project1_top;

architecture rtl of Project1_top is


  --For displaying.
  COMPONENT SEG7_LUT_4
    PORT(
	  clk50 : in std_logic;
	  h0   : out STD_LOGIC_VECTOR( 6 downto 0 );
	  h1   : out STD_LOGIC_VECTOR( 6 downto 0 );
	  h2   : out STD_LOGIC_VECTOR( 6 downto 0 );
	  h3   : out STD_LOGIC_VECTOR( 6 downto 0 );
	  mSEG7_DIG : in STD_LOGIC_VECTOR ( 15 downto 0 )
	);
  END COMPONENT;

  --siod and sioc are used to communicate I'2C
  -- Controller uses I2C to set register data to the
  --  OV7670.
  COMPONENT OV7670_driver
    PORT(
	  iclk50   : in    STD_LOGIC;
	  config_finished : out std_logic;
	  sioc  : out   STD_LOGIC;
	  siod  : inout STD_LOGIC;
	  sw : in STD_LOGIC_VECTOR( 9 downto 0 );
	  key : in STD_LOGIC_VECTOR( 3 downto 0 )
	  --readcheck : out STD_LOGIC_VECTOR (7 downto 0)
	);
  END COMPONENT;

  -- OVCapture gets the data from OV7670 camera

  COMPONENT OV7670_capture
    PORT(
	  pclk : IN std_logic; -- camera clock
	  vsync : IN std_logic;
	  href  : IN std_logic;
	  dport  : IN std_logic_vector(7 downto 0); -- data        
	  surv : in std_logic;
	  addr  : OUT std_logic_vector(12 downto 0); --test 18, 14 previous
	  dout  : OUT std_logic_vector(15 downto 0);
	  we    : OUT std_logic; -- write enable
	  maxx    : OUT natural -- write enable
	);
  END COMPONENT;

  -- VGA determines the active area as well as gets the data from frame buffer
  --  Does the final setting of  r g b  output to the screen
  COMPONENT vga_driver 
    Port ( 
	   iVGA_CLK       : in  STD_LOGIC;
	   r     : out STD_LOGIC_VECTOR(3 downto 0);
	   g   : out STD_LOGIC_VECTOR(3 downto 0);
	   b    : out STD_LOGIC_VECTOR(3 downto 0);
	   hs   : out STD_LOGIC;
	   vs   : out STD_LOGIC;
	   surv : in std_logic;
	   debug : in natural;
	   debug2 : in natural;
	   motion : out natural;
	   buffer_addr : out STD_LOGIC_VECTOR(12 downto 0);
	   buffer_data : in  STD_LOGIC_VECTOR(15 downto 0)
	 );
  end COMPONENT;


  --The frame buffer is reference by OVdriver
  -- and data input is by OVCapture
  COMPONENT framebuffer 
    PORT
    (
      rdclock		: IN STD_LOGIC ;
      rdaddress	: IN STD_LOGIC_VECTOR (12 downto 0);
      q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);--data out

      wrclock		: IN STD_LOGIC;
      wraddress	: IN STD_LOGIC_VECTOR (12 downto 0);
      data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
      wren		: IN STD_LOGIC
    );
  END COMPONENT;


  constant CNT_MAX : integer := 50000000;

  --Local wires
  signal mSEG7 : std_logic_vector ( 15 downto 0) := (others => '0');
  signal cnt : unsigned(24 downto 0);
  signal displaycn: unsigned(1 downto 0);
  signal blink : std_logic;
  signal xclk  : std_logic := '0';   
  signal config_finished : std_logic;

  signal buffer_addr  : std_logic_vector(12 downto 0) := (others => '0');
  signal buffer_data  : std_logic_vector(15 downto 0) := (others => '0');
  signal capture_addr  : std_logic_vector(12 downto 0);
  signal capture_data  : std_logic_vector(15 downto 0);
  signal capture_we    : std_logic; -- write enable.
  
  --modes
  signal surveillance : std_logic;
  signal surveillance2 : std_logic;
  signal survmode : std_logic;

  --buttons
  signal key0push : std_logic;
  signal key1push : std_logic;
  signal key2push : std_logic;
  signal key3push : std_logic;

  --debugging
  signal debug : natural := 0;
  signal debug2 : natural := 0;
  signal max : natural := 0;
  signal motion : natural := 0;
  signal motionaddr : std_logic_vector(3 downto 0) := (others => '0');
  signal sums : unsigned(15 downto 0) := (others => '0');

begin

  with KEY(0) select key0push <= '1' when '0', '0' when others;
  with KEY(1) select key1push <= '1' when '0', '0' when others;
  -- key 3 used in registers.
  with KEY(2) select key2push <= '1' when '0', '0' when others;
  with KEY(3) select key3push <= '1' when '0', '0' when others;
  --SW1 to 6 used by ovregisters
  with SW(7) select surveillance <= '1' when '1', '0' when others;
  with SW(8) select surveillance2 <= '1' when '1', '0' when others;

  display : SEG7_LUT_4 PORT MAP
  (	  
    clk50 => xclk,
    h0 => HEX0,
    h1 => HEX1,
    h2 => HEX2,
    h3 => HEX3,
    mSEG7_DIG => mSEG7
  );

  ovdr : OV7670_driver PORT MAP
  (
    iclk50  => xclk,
    config_finished => config_finished,
    sioc  => ov7670_sioc,
    siod  => ov7670_siod,
    sw => SW,
    key => KEY
    --readcheck => readcheck
  );


  vgadr : vga_driver PORT MAP
  (
    iVGA_CLK       => xclk,
    r    => VGA_R,
    g   => VGA_G,
    b    => VGA_B,
    hs   => VGA_HS,
    vs   => VGA_VS,
    surv => surveillance,
    debug => debug,
    debug2 => debug2,
    motion => motion,
    buffer_addr  => buffer_addr,
    buffer_data => buffer_data
  );

  ovcap : OV7670_capture PORT MAP
  (
    pclk  => OV7670_PCLK,
    vsync => OV7670_VSYNC,
    href  => OV7670_HREF,
    dport  => OV7670_D,
    surv => survmode,
    addr  => capture_addr,
    dout  => capture_data,
    maxx => max,
    we    => capture_we
  );

  fb : framebuffer PORT MAP 
  (
    rdclock  => CLOCK_50,
    rdaddress => buffer_addr,
    q => buffer_data,

    wrclock => OV7670_PCLK,
    wraddress => capture_addr,
    data  => capture_data,
    wren   => capture_we
  );

  OV7670_RESET <= '1';                   -- Normal mode
  OV7670_PWDN  <= '0';                   -- Power device up
  OV7670_XCLK <= xclk;

  process(CLOCK_50)

  begin
    if rising_edge(CLOCK_50) then
      if cnt=CNT_MAX then
	cnt <= (others => '0');
	blink <= not blink;
      --mSEG7 <= x"0000" or std_logic_vector(to_unsigned(debug-debug2,mSEG7'length));
      --mSEG7 <= std_logic_vector(to_unsigned(max,mSEG7'length));
       mSEG7 <= std_logic_vector(sums);
      else
	cnt <= cnt + 1;
      end if;
      xclk <= not xclk; --System clock for OV and VGA 25mhz
    end if;
  end process;

  process(key0push)
  begin
    if key0push = '1' then
      debug <= debug + 1;
    end if;
  end process;

  process(key1push)
  begin
    if key1push = '1' then
      debug2 <= debug2 + 1;
    end if;
  end process;

  process(motion)
    type MDATA is array (15 downto 0) of unsigned(9 downto 0);
    variable motiondata : MDATA;
    variable sum : unsigned(15 downto 0) := (others => '0');
  begin	
    motiondata(to_integer(unsigned(motionaddr))) := to_unsigned(motion, 10);
    sum := (others => '0');
    for n in motiondata'range loop
      sum:= sum+ motiondata(n);                         
    end loop;
    sums <= sum;
    motionaddr <= std_logic_vector(unsigned(motionaddr) + 1);
  end process;

  process(surveillance,surveillance2)
  begin
    survmode <= surveillance or surveillance2;
  end process;

  LEDG <= key3push & '0' & key2push & '0' & key1push & config_finished & key0push & blink;
  LEDR <= SW(9) & SW(8) & SW(7) & SW(6) & SW(5) & SW(4) & SW(3) & SW(2) & SW(1) & SW(0);
end rtl;
