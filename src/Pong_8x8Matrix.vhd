 -------------------------------------------------------------------------------
--
-- SHA_1.vhd
--
-- v. 1.0 2020-10-30 Pierre Langlois
-- version à compléter, labo #4 INF3500, automne 2021
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;  	
use work.all;
use work.pong_utilitaires_pkg.all;



entity Pong_8x8Matrix is 

    port (
	clk : in std_logic;
	matrix : in matrix_points; 
	cols, rows : out unsigned(7 downto 0)
    );
end Pong_8x8Matrix;

architecture arch of Pong_8x8Matrix is
begin
    process(clk)	 
	variable row_count : unsigned (2 downto 0);
    begin
        if rising_edge(clk) then

			cols <= X"FF" xor matrix(to_integer(row_count));
			rows <= to_unsigned(2 **  to_integer(row_count), rows'length);
			row_count := row_count + 1;	 	
		

       end if;
    end process;

end arch;	

--		 cols <= to_unsigned(0, cols'length);
--		 rows <= to_unsigned(8, rows'length);