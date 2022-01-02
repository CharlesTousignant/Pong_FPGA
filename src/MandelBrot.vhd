library IEEE;
use IEEE.STD_LOGIC_1164.ALL;	   
use ieee.numeric_std.all;  	
use work.pong_utilitaires_pkg.all;	
use ieee.fixed_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

entity MandelBrot is  
    generic(
        decimal_precision : integer := 8;
        max_iter : integer := 15
    );
    Port ( clk : in STD_LOGIC;
           start_x, start_y: sfixed(4 downto -decimal_precision);
		   new_point : in std_logic;
		   iterations : out unsigned (3 downto 0);
		   done : out std_logic
           );
end MandelBrot;

architecture arch of MandelBrot is

signal x_C, y_C, x_n, y_n : sfixed(4 downto -decimal_precision); 	 
signal curr_iter : unsigned(3 downto 0) := to_unsigned(0, 4);

begin 
	
	process(clk)
	begin
		if(rising_edge(clk)) then
			if ( new_point = '1') then 
						
				x_C <= start_x;
				y_C <= start_y;
				x_n <= to_sfixed(0, 4, -decimal_precision);
				y_n <= to_sfixed(0, 4, -decimal_precision);
				
				curr_iter <= x"0";
				done <= '0';
				
			elsif ((x_n * x_n + y_n * y_n) > 4) then 
				iterations <= curr_iter;
				done <= '1';	
			else 
				if( curr_iter < max_iter) then
					
					x_n <= resize((x_n * x_n - y_n * y_n) + 	x_C, x_n);
					y_n <= resize((2 * x_n * y_n) + y_c, y_n);
					curr_iter <= curr_iter + 1;
				else
				    -- we didn't diverge
					iterations <= to_unsigned(0, 4);
					done <= '1';	
                end if;
			end if;	
		end if;
	end process;
	
end arch;