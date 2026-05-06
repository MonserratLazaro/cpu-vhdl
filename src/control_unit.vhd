-- =============================================================================
-- Módulo: Control Unit
-- =============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity control_unit is
    port (
        op     : in  STD_LOGIC_VECTOR(6 downto 0);
        f7     : in  STD_LOGIC_VECTOR(6 downto 0);
        reg_w  : out STD_LOGIC;
        alu_c  : out STD_LOGIC_VECTOR(3 downto 0);
        is_jal : out STD_LOGIC
    );
end entity control_unit;

architecture arch of control_unit is
begin
    process(op, f7)
    begin
        reg_w  <= '0';
        alu_c  <= "0000";
        is_jal <= '0';

        case op is
            when "0110011" =>           -- R-type (ADD, MUL)
                reg_w  <= '1';
                is_jal <= '0';
                if f7 = "0000001" then
                    alu_c <= "0001";    -- MUL
                else
                    alu_c <= "0000";    -- ADD
                end if;
            when "1101111" =>           -- JAL
                reg_w  <= '0';
                alu_c  <= "0000";
                is_jal <= '1';
            when others =>
                null;
        end case;
    end process;
end arch;