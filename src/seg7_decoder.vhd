-- =============================================================================
-- Módulo: Decoder
-- =============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity seg7_decoder is
    port (
        digit : in  integer range 0 to 9;
        seg   : out STD_LOGIC_VECTOR(6 downto 0)  -- seg(6)=g, seg(0)=a
    );
end entity seg7_decoder;

architecture arch of seg7_decoder is
begin
    process(digit)
    begin
        case digit is
            --                 gfedcba
            when 0 =>  seg <= "1000000";  -- 0
            when 1 =>  seg <= "1111001";  -- 1
            when 2 =>  seg <= "0100100";  -- 2
            when 3 =>  seg <= "0110000";  -- 3
            when 4 =>  seg <= "0011001";  -- 4
            when 5 =>  seg <= "0010010";  -- 5
            when 6 =>  seg <= "0000010";  -- 6
            when 7 =>  seg <= "1111000";  -- 7
            when 8 =>  seg <= "0000000";  -- 8
            when 9 =>  seg <= "0010000";  -- 9
            when others => seg <= "1111111";  -- apagado
        end case;
    end process;
end arch;
