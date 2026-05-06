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
begin
    process(a, b, ctrl)
		begin
			if ctrl = "0000" then
				res <= std_logic_vector(signed(a) + signed (b));
			elsif ctrl = "0001" then
				res <= std_logic_vector(resize(signed(a) * signed (b), 32));
			else
				res <= (others=>'0');
			end if;
	end process;
end arch;
