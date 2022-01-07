-- Based on template vga controller from Digilent's example on github: https://github.com/Digilent/Basys-3-GPIO/blob/master/src/hdl/vga_ctrl.vhd

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;	    	
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.std_logic_unsigned.all;
use ieee.math_real.all;
use work.pong_utils_pkg.all;

entity vga_ctrl is
    Port ( pxl_clk : in STD_LOGIC;
		   pong_matrix : in matrix_points;
		   fractal : in frame_info;
		   fractal_calculated : in std_logic;
           VGA_HS_O : out STD_LOGIC;
           VGA_VS_O : out STD_LOGIC;
           VGA_RED_O : out STD_LOGIC_VECTOR (3 downto 0);
           VGA_BLUE_O : out STD_LOGIC_VECTOR (3 downto 0);
           VGA_GREEN_O : out STD_LOGIC_VECTOR (3 downto 0)
           );
end vga_ctrl;

architecture Behavioral of vga_ctrl is
	
	
	--***1280x1024@60Hz***--
	constant FRAME_WIDTH : natural := 1280;
	constant FRAME_HEIGHT : natural := 1024; 
	
	constant pong_h_block_width : natural := FRAME_WIDTH / game_pixel_width; 
	constant pong_v_block_width : natural := FRAME_HEIGHT / game_pixel_width;
	
	constant fractal_h_block_width : natural := FRAME_WIDTH / H_RES; 
	constant fractal_v_block_width : natural := FRAME_HEIGHT / V_RES;
	
	constant H_BP : natural := 248; -- H back porch width (pixels)
	constant H_FP : natural := 48; --H front porch width (pixels)
	constant H_PW : natural := 112; --H sync pulse width (pixels)
	constant H_MAX : natural := FRAME_WIDTH + H_BP + H_FP + H_PW; --H total period (pixels)
	
	constant V_BP : natural := 38; -- V back porch width (lines)
	constant V_FP : natural := 1; --V front porch width (lines)
	constant V_PW : natural := 3; --V sync pulse width (lines)
	constant V_MAX : natural := FRAME_HEIGHT + V_BP + V_FP + V_PW; --V total period (lines)
	
	constant H_POL : std_logic := '1';
	constant V_POL : std_logic := '1';		
  
  -------------------------------------------------------------------------
  
  -- VGA Controller specific signals: Counters, Sync, R, G, B
  
  -------------------------------------------------------------------------
  -- The active signal is used to signal the active region of the screen (when not blank)
  signal active  : std_logic;
  
  -- Horizontal and Vertical counters
  signal h_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
  signal v_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
  
  -- Pipe Horizontal and Vertical Counters
  signal h_cntr_reg_dly   : std_logic_vector(11 downto 0) := (others => '0');
  signal v_cntr_reg_dly   : std_logic_vector(11 downto 0) := (others => '0');
  
  -- Horizontal and Vertical Sync
  signal h_sync_reg : std_logic := not(H_POL);
  signal v_sync_reg : std_logic := not(V_POL);
  -- Pipe Horizontal and Vertical Sync
  signal h_sync_reg_dly : std_logic := not(H_POL);
  signal v_sync_reg_dly : std_logic :=  not(V_POL);
  
  -- VGA R, G and B signals coming from the main multiplexers
  signal vga_red_cmb   : std_logic_vector(3 downto 0);
  signal vga_green_cmb : std_logic_vector(3 downto 0);
  signal vga_blue_cmb  : std_logic_vector(3 downto 0);
  --The main VGA R, G and B signals, validated by active
  signal vga_red    : std_logic_vector(3 downto 0);
  signal vga_green  : std_logic_vector(3 downto 0);
  signal vga_blue   : std_logic_vector(3 downto 0);
  -- Register VGA R, G and B signals
  signal vga_red_reg   : std_logic_vector(3 downto 0) := (others =>'0');
  signal vga_green_reg : std_logic_vector(3 downto 0) := (others =>'0');
  signal vga_blue_reg  : std_logic_vector(3 downto 0) := (others =>'0');
  
  
  -----------------------------------------------------------
  -- Signals for generating the background (moving colorbar)
  -----------------------------------------------------------
  signal cntDyn                : integer range 0 to 2**28-1; -- counter for generating the colorbar
  signal intHcnt                : integer range 0 to H_MAX - 1;
  signal intVcnt                : integer range 0 to V_MAX - 1;
  -- Colorbar red, greeen and blue signals
  signal bg_red                 : std_logic_vector(3 downto 0);
  signal bg_blue             : std_logic_vector(3 downto 0);
  signal bg_green             : std_logic_vector(3 downto 0);
  -- Pipe the colorbar red, green and blue signals
  signal bg_red_dly            : std_logic_vector(3 downto 0) := (others => '0');
  signal bg_green_dly        : std_logic_vector(3 downto 0) := (others => '0');
  signal bg_blue_dly        : std_logic_vector(3 downto 0) := (others => '0');
  
  signal curr_h_block, curr_v_block : integer range 0 to game_pixel_width;
  signal curr_h_block_fractal : integer range 0 to H_RES - 1;
  signal curr_v_block_fractal : integer range 0 to V_RES - 1;
begin
       
       ---------------------------------------------------------------
       
       -- Generate Horizontal, Vertical counters and the Sync signals
       
       ---------------------------------------------------------------
         -- Horizontal counter
         process (pxl_clk)
         begin
           if (rising_edge(pxl_clk)) then
             if (h_cntr_reg = (H_MAX - 1)) then
               h_cntr_reg <= (others =>'0');
             else
               h_cntr_reg <= h_cntr_reg + 1;
             end if;
           end if;
         end process;
		 
         -- Vertical counter
         process (pxl_clk)
         begin
           if (rising_edge(pxl_clk)) then
             if ((h_cntr_reg = (H_MAX - 1)) and (v_cntr_reg = (V_MAX - 1))) then
               v_cntr_reg <= (others =>'0');
             elsif (h_cntr_reg = (H_MAX - 1)) then
               v_cntr_reg <= v_cntr_reg + 1;
             end if;
           end if;
         end process;	
		 
         -- Horizontal sync
         process (pxl_clk)
         begin
           if (rising_edge(pxl_clk)) then
             if (h_cntr_reg >= (H_FP + FRAME_WIDTH - 1)) and (h_cntr_reg < (H_FP + FRAME_WIDTH - 1 + H_PW )) then
               h_sync_reg <= H_POL;
             else
               h_sync_reg <= not(H_POL);
             end if;
           end if;
         end process;
         -- Vertical sync
         process (pxl_clk)
         begin
           if (rising_edge(pxl_clk)) then
             if (v_cntr_reg >= (V_FP + FRAME_HEIGHT - 1)) and (v_cntr_reg < (V_FP + FRAME_HEIGHT - 1 + V_PW)) then
               v_sync_reg <= V_POL;
             else
               v_sync_reg <= not(V_POL);
             end if;
           end if;
         end process;
         
       --------------------
       
       -- The active 
       
       --------------------  
         -- active signal
         active <= '1' when h_cntr_reg_dly < FRAME_WIDTH and v_cntr_reg_dly < FRAME_HEIGHT
                   else '0';
       
       
     ---------------------------------------
     
     -- Generate moving colorbar background
     
     ---------------------------------------
     
     process(pxl_clk)
     begin
         if(rising_edge(pxl_clk)) then
             cntdyn <= cntdyn + 1;
         end if;
     end process;
    
     intHcnt <= conv_integer(h_cntr_reg);
     intVcnt <= conv_integer(v_cntr_reg);
     
	 curr_h_block <= intHcnt / pong_h_block_width;
	 curr_v_block <= intVcnt / pong_v_block_width;
	 
	 curr_h_block_fractal <= intHcnt / fractal_h_block_width ;
	 curr_v_block_fractal <= intVcnt / fractal_v_block_width ;
	 
	 with pong_matrix(curr_h_block)(curr_v_block) select bg_red <=
	 x"F" when '1',
	 fractal(curr_v_block_fractal)(curr_h_block_fractal) when others; 
	 --x"0" when others;
	 
	 with pong_matrix(curr_h_block)(curr_v_block) select bg_green <=
	 x"F" when '1',
	 fractal(curr_v_block_fractal)(curr_h_block_fractal) when others;
	 --x"0" when others;
	 
	 with pong_matrix(curr_h_block)(curr_v_block) select bg_blue <=
	 x"F" when '1',
	 fractal(curr_v_block_fractal)(curr_h_block_fractal) when others;
	 --x"0" when others;
	 
--     bg_green <= fractal(curr_v_block_fractal)(curr_h_block_fractal);
--     bg_blue <= fractal(curr_v_block_fractal)(curr_h_block_fractal);
--     bg_red <= fractal(curr_v_block_fractal)(curr_h_block_fractal);
	 
--	 bg_red <= conv_std_logic_vector((-intvcnt - inthcnt - cntDyn/2**20),8)(7 downto 4);
--	 bg_green <= conv_std_logic_vector((inthcnt - cntDyn/2**20),8)(7 downto 4);
--	 bg_blue <= conv_std_logic_vector((intvcnt - cntDyn/2**20),8)(7 downto 4);
     
    
    ---------------------------------------------------------------------------------------------------
    
    -- Register Outputs coming from the displaying components and the horizontal and vertical counters
    
    ---------------------------------------------------------------------------------------------------
      process (pxl_clk)
      begin
        if (rising_edge(pxl_clk)) then
      
            bg_red_dly            <= bg_red;
            bg_green_dly        <= bg_green;
            bg_blue_dly            <= bg_blue;
            
            h_cntr_reg_dly <= h_cntr_reg;
            v_cntr_reg_dly <= v_cntr_reg;

        end if;
      end process;

    ----------------------------------
    
    -- VGA Output Muxing
    
    ----------------------------------

    vga_red <= bg_red_dly;
    vga_green <= bg_green_dly;
    vga_blue <= bg_blue_dly;
           
    ------------------------------------------------------------
    -- Turn Off VGA RBG Signals if outside of the active screen
    -- Make a 4-bit AND logic with the R, G and B signals
    ------------------------------------------------------------
    vga_red_cmb <= (active & active & active & active) and vga_red;
    vga_green_cmb <= (active & active & active & active) and vga_green;
    vga_blue_cmb <= (active & active & active & active) and vga_blue;
    
    
    -- Register Outputs
     process (pxl_clk)
     begin
       if (rising_edge(pxl_clk)) then
    
         v_sync_reg_dly <= v_sync_reg;
         h_sync_reg_dly <= h_sync_reg;
         vga_red_reg    <= vga_red_cmb;
         vga_green_reg  <= vga_green_cmb;
         vga_blue_reg   <= vga_blue_cmb;      
       end if;
     end process;
    
     -- Assign outputs
     VGA_HS_O     <= h_sync_reg_dly;
     VGA_VS_O     <= v_sync_reg_dly;
     VGA_RED_O    <= vga_red_reg;
     VGA_GREEN_O  <= vga_green_reg;
     VGA_BLUE_O   <= vga_blue_reg;

end Behavioral;