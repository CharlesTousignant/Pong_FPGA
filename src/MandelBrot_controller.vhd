----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/01/2022 02:16:09 PM
-- Design Name: 
-- Module Name: MandelBrot_controller - Behavioralarch
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;	   
use ieee.numeric_std.all;  
use work.all;	
use work.pong_utilitaires_pkg.all;	
use ieee.fixed_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MandelBrot_controller is
    generic(
        constant decimal_precision : integer := 8
    );
 
     Port (
         clk : in std_logic;
         reset : in std_logic;
         image : out frame_info;
         done : out std_logic
      );
end MandelBrot_controller;

architecture arch of MandelBrot_controller is
signal curr_pix_x : integer range 0 to H_RES - 1 := 0;
signal curr_pix_y : integer range 0 to V_RES - 1 := 0;


constant x_increment : sfixed(4 downto -decimal_precision) := to_sfixed(4 / H_RES, 4, -decimal_precision);
constant y_increment : sfixed(4 downto -decimal_precision) := to_sfixed(4 / V_RES, 4, -decimal_precision);


signal iterations : unsigned (3 downto 0);
signal mandelBrot_calc_done : std_logic := '0';

signal give_new_point : std_logic;
signal x_C, y_C : sfixed(4 downto -decimal_precision);
begin
    
    mandelBrot_calc : entity Mandelbrot(arch)
    port map (
        clk => clk,
        start_x => x_C,
        start_y => y_c,
        new_point => give_new_point,
        iterations => iterations,
        done => mandelBrot_calc_done
    );
    

    
    process(clk)
    begin
        if (rising_edge(clk)) then
            if(reset = '1') then
                curr_pix_x <= 0;
                curr_pix_y <= 0;
                give_new_point <= '1';
                done <= '0';
                image <= (others => (others => X"0"));
                
            elsif( give_new_point = '1') then
                give_new_point <= '0';
            else 
                if(mandelBrot_calc_done = '1') then
                    -- If we just got the result for the last pixel at bottom right, then we're done
                    if( curr_pix_x = H_RES -1 and curr_pix_y = V_RES - 1) then
                        image(curr_pix_y)(curr_pix_x) <= std_logic_vector(iterations);
                        done <= '1';
                    else
                        -- if we're at the end of a line, increment both
                        if (curr_pix_x = H_RES - 1) then
                            curr_pix_x <= curr_pix_x + 1;
                            curr_pix_y <= curr_pix_y + 1;
                        -- if not just increment the x
                        else
                            curr_pix_x <= curr_pix_x + 1;
                        end if;
                        give_new_point <= '1';
                    end if;
                 end if;
             end if;
        end if;
    end process;
    x_C <= resize(to_sfixed(-2, 4, -decimal_precision) + curr_pix_x * x_increment, x_C);
    y_C <= resize(to_sfixed(2, 4, -decimal_precision) - curr_pix_y * y_increment , y_C);         
end arch;
