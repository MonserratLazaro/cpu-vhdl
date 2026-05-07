-- =============================================================================
-- Módulo: ALU  (ADD y MUL)
-- =============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu is
    port (
        a    : in  STD_LOGIC_VECTOR(31 downto 0);
        b    : in  STD_LOGIC_VECTOR(31 downto 0);
        ctrl : in  STD_LOGIC_VECTOR(3 downto 0);
        res  : out STD_LOGIC_VECTOR(31 downto 0)
    );
end entity alu;

architecture arch of alu is
    signal mul_result : SIGNED(63 downto 0);
begin
    process(a, b, ctrl)
    begin
        case ctrl is
            when "0000" =>
                res <= std_logic_vector(signed(a) + signed(b));
            when "0001" =>
                mul_result <= signed(a) * signed(b);
                res        <= std_logic_vector(mul_result(31 downto 0));
            when others =>
                res <= (others => '0');
        end case;
    end process;
end arch;