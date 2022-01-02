---------------------------------------------------------------------------------------------------
-- 
-- top_labo_4.vhd
--
-- Pierre Langlois
-- v. 1.1, 2021/03/06 pour le laboratoire #4
--
-- Digilent Basys 3 Artix-7 FPGA Trainer Board 
--
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;  
use work.utilitaires_inf3500_pkg.all;	   
use work.pong_utilitaires_pkg.all;
use work.all;	   


entity top_Pong_8x8Matrix is
    port(
		clk : in std_logic; -- l'horloge de la carte à 100 MHz	   
		led : out STD_LOGIC_VECTOR (15 downto 0);
		JA : in STD_LOGIC_VECTOR (7 downto 0);
        btnC : in std_logic; -- bouton du centre	  
		cols, rows : out unsigned(7 downto 0);
		
	   VGA_RED      : out  STD_LOGIC_VECTOR (3 downto 0);
       VGA_BLUE     : out  STD_LOGIC_VECTOR (3 downto 0);
       VGA_GREEN    : out  STD_LOGIC_VECTOR (3 downto 0);
       VGA_VS       : out  STD_LOGIC;
       VGA_HS       : out  STD_LOGIC
    );
end;

architecture arch of top_Pong_8x8Matrix is	

component xadc_wiz_0 is
	port( daddr_in : in STD_logic_vector (6 downto 0); -- address bus for the dynamic reconfiguration port
		den_in : in std_logic; 					   -- enable signal for the dynamic reconfiguration port
		di_in : in std_logic_vector (15 downto 0); -- input data bus for the dynamic reconfiguration port
		dwe_in : in std_logic; -- write enable for teh dynamic reoncfiguration port
		do_out : out std_logic_vector(15 downto 0); -- output data bus for dynamic reconfiguration port
		drdy_out : out std_logic; -- data ready signal for teh dynamic reconfiguration port
		dclk_in : in std_logic; --clock input for the dynamic reconfiguration port
		reset_in : in std_logic; -- reset signal for the system monitor control logic
		vauxp5 : in std_logic; -- auxiliary channel 14
		vauxn5 : in std_logic; 
		busy_out : out std_logic; -- adc busy signal
		channel_out : out std_logic_vector(4 downto 0); -- channel selection outputs
		eoc_out : out std_logic; -- end of conversion signal
		eos_out : out std_logic; -- end of sequence signal
		alarm_out : out std_logic; -- OR'ed output of all the alarms
		vp_in : in std_logic; --dedicated analog input pair
		vn_in : std_logic
		);	  
end component;
			
signal clk_30_Hz : std_logic;
signal clk_25MHz : std_logic;
constant test_matrix : matrix_points := (others => x"40");
constant clock_speed : integer := 512;
constant pixel_clock_speed : integer := 25e6;

signal channel_out : std_logic_vector(4 downto 0);
signal daddr_in  : std_logic_vector(6 downto 0);
signal eoc_out : std_logic;
signal do_out  : std_logic_vector(15 downto 0);  
signal anal_p, anal_n : std_logic; 	   

signal pong_matrix : matrix_points := (others => x"00");

signal fractal_image : frame_info;
signal fractal_calculated : std_logic;

begin					   
	
	clk_inst_30_Hz : entity generateur_horloge_precis(arch) generic map (100e6, clock_speed) port map (clk, clk_30_Hz);
	clk_inst_25MHz : entity generateur_horloge_precis(arch) generic map (100e6, pixel_clock_speed) port map (clk, clk_25MHz);
	daddr_in <= "00" & channel_out;
	anal_p <= JA(4);
	anal_n <= JA(0);
	led <= x"00" & do_out(15 downto 8);
	
    -- instantiation du module				
	ADCimp : xadc_wiz_0
	port map( daddr_in => daddr_in, -- choses which input to look at
	den_in => eoc_out, -- enable signal,	
	di_in => (others => '0'), -- input data bus ???
	dwe_in => '0', -- write enable
	do_out => do_out, --output data bus
	drdy_out => open, -- readyInt
	dclk_in => clk, 
	reset_in => '0',
	vauxp5 => anal_p,
	vauxn5 => anal_n,
	busy_out => open,
	channel_out => channel_out,
	eoc_out => eoc_out,							 -- end of conversion signal
	eos_out => open, --end of sequence signal							
    alarm_out => open,
	vp_in => '0',
	vn_in => '0'
	);
	
	mandelBrot_calc  : entity MandelBrot_controller(arch)
	port map(
	clk => clk,
	reset => btnC,
	image => fractal_image,
	done => fractal_calculated
	);
	
	vga : entity vga_ctrl(Behavioral)
	port map (
	pxl_clk => clk, 
	pong_matrix => pong_matrix,
	fractal => fractal_image,
	fractal_calculated =>fractal_calculated,
	VGA_HS_O => VGA_HS,
    VGA_VS_O => VGA_VS,
	VGA_RED_O => VGA_RED,
    VGA_BLUE_O => VGA_BLUE,
    VGA_GREEN_O => VGA_GREEN
	);
	
	
    module_pong : entity Pong_GameLoop(arch)  
	generic map(
	clock_speed => clock_speed
	)
	
    port map (
    clk => clk_30_Hz,
	matrix => pong_matrix,
    reset => btnC,
	cols => cols,
	rows => rows,
	joystick_input => do_out(15 downto 4)
    );
    
        
end arch;