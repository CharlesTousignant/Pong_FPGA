-- Clock generator modified slightly from code from INF3500 class, given by Pierre Langlois

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity clock_gen is
    generic (
        freq_in : natural := 2;
        freq_out : natural := 1
    );
    port(
        clk_in : in std_logic;
        clk_out : out std_logic
    );
end clock_gen;

architecture arch of clock_gen is

begin
    
    assert (real(freq_in) / real(freq_out)) / 2.0 <= real(natural'high)
        report "The ratio of clock frequency is too high, > " & integer'image(natural'high) & "." severity failure;
    assert freq_in >= 2 * freq_out report
        "The output clock frequency needs to be at least half the input clock frequency." severity failure;
    
    
    process(clk_in)
    constant max_count : natural := (freq_in / freq_out) / 2;
    variable count : natural range 0 to max_count;
    variable clk_int : std_logic := '0';
    begin
        if rising_edge(clk_in) then
            if count = max_count then
                clk_int := not(clk_int);
                count := 0;
            else
                count := count + 1;
            end if;
        end if;
        clk_out <= clk_int;
    end process;

end arch;