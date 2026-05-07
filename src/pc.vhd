-- =============================================================================
-- Módulo: PC
-- =============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pc is
    port (
        clk : in  STD_LOGIC;
        rst : in  STD_LOGIC;
        d   : in  STD_LOGIC_VECTOR(31 downto 0);
        q   : out STD_LOGIC_VECTOR(31 downto 0)
    );
end entity pc;

architecture arch of pc is
begin
    process(clk, rst)
    begin
        if rst = '1' then
            q <= (others => '0');
        elsif rising_edge(clk) then
            q <= d;
        end if;
    end process;
end arch;