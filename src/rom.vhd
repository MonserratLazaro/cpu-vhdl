-- =============================================================================
-- Módulo: ROM 
-- =============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rom is
    port (
        addr  : in  STD_LOGIC_VECTOR(31 downto 0);
        instr : out STD_LOGIC_VECTOR(31 downto 0)
    );
end entity rom;

architecture arch of rom is
    type rom_type is array (0 to 63) of STD_LOGIC_VECTOR(31 downto 0);
    signal rom_mem : rom_type := (
        0 => x"023082B3",   -- mul x5, x1, x3   → x5 = m * x
        1 => x"002282B3",   -- add x5, x5, x2   → x5 = m*x + b  (y final)
        2 => x"007181B3",   -- add x3, x3, x7   → x3 = x + 1
        3 => x"FF5FF06F",   -- jal x0, -12      → volver a instrucción 0
        others => x"00000000"
    );
begin
    instr <= rom_mem(to_integer(unsigned(addr(7 downto 2))));
end arch;