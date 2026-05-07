-- =============================================================================
-- Módulo: Register File
-- =============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity register_file is
    port (
        clk    : in  STD_LOGIC;
        rst_rf : in  STD_LOGIC;                       
        we     : in  STD_LOGIC;
        rs1    : in  STD_LOGIC_VECTOR(4 downto 0);
        rs2    : in  STD_LOGIC_VECTOR(4 downto 0);
        rd     : in  STD_LOGIC_VECTOR(4 downto 0);
        wd     : in  STD_LOGIC_VECTOR(31 downto 0);
        rd1    : out STD_LOGIC_VECTOR(31 downto 0);
        rd2    : out STD_LOGIC_VECTOR(31 downto 0)
    );
end entity register_file;

architecture Behavioral of register_file is
    type reg_array is array (0 to 31) of STD_LOGIC_VECTOR(31 downto 0);
    signal rf : reg_array := (
        0  => x"00000000",
        1  => x"00000003",  -- x1 = m = 3
        2  => x"00000005",  -- x2 = b = 5
        3  => x"00000000",  -- x3 = x = 0
        4  => x"00000064",  -- x4 = 100 (número de muestras)
        5  => x"00000000",  -- x5 = y (resultado)
        6  => x"00000000",  -- x6 = contador
        7  => x"00000001",  -- x7 = 1 (incremento)
        others => x"00000000"
    );
begin
    rd1 <= rf(to_integer(unsigned(rs1))) when (rs1 /= "00000") else (others => '0');
    rd2 <= rf(to_integer(unsigned(rs2))) when (rs2 /= "00000") else (others => '0');

    process(clk, rst_rf)
    begin
        if rst_rf = '1' then
            rf(0) <= x"00000000";
            rf(1) <= x"00000003";  -- x1 = m = 3
            rf(2) <= x"00000005";  -- x2 = b = 5
            rf(3) <= x"00000000";  -- x3 = x = 0
            rf(4) <= x"00000064";
            rf(5) <= x"00000000";
            rf(6) <= x"00000000";
            rf(7) <= x"00000001";  -- x7 = 1
        elsif rising_edge(clk) then
            if (we = '1' and rd /= "00000") then
                rf(to_integer(unsigned(rd))) <= wd;
            end if;
        end if;
    end process;
end Behavioral;
