-- =============================================================================
-- Módulo: bcd_extractor
-- Descripción: Convierte un número entero (0-999) a 3 dígitos BCD
--              usando restas sucesivas (sin división, sintetizable).
--
-- Entradas:  valor  → número a convertir (0-999)
-- Salidas:   d2     → centenas (0-9)
--            d1     → decenas  (0-9)
--            d0     → unidades (0-9)
--
-- Ejemplo: valor=32 → d2=0, d1=3, d0=2
-- =============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bcd_extractor is
    port (
        valor : in  integer range 0 to 999;
        d2    : out integer range 0 to 9;   -- centenas
        d1    : out integer range 0 to 9;   -- decenas
        d0    : out integer range 0 to 9    -- unidades
    );
end entity bcd_extractor;

architecture arch of bcd_extractor is
begin
    process(valor)
        variable tmp : integer range 0 to 999;
        variable c   : integer range 0 to 9;
    begin
        tmp := valor;

        -- Centenas
        c := 0;
        if    tmp >= 900 then c := 9; tmp := tmp - 900;
        elsif tmp >= 800 then c := 8; tmp := tmp - 800;
        elsif tmp >= 700 then c := 7; tmp := tmp - 700;
        elsif tmp >= 600 then c := 6; tmp := tmp - 600;
        elsif tmp >= 500 then c := 5; tmp := tmp - 500;
        elsif tmp >= 400 then c := 4; tmp := tmp - 400;
        elsif tmp >= 300 then c := 3; tmp := tmp - 300;
        elsif tmp >= 200 then c := 2; tmp := tmp - 200;
        elsif tmp >= 100 then c := 1; tmp := tmp - 100;
        end if;
        d2 <= c;

        -- Decenas
        c := 0;
        if    tmp >= 90 then c := 9; tmp := tmp - 90;
        elsif tmp >= 80 then c := 8; tmp := tmp - 80;
        elsif tmp >= 70 then c := 7; tmp := tmp - 70;
        elsif tmp >= 60 then c := 6; tmp := tmp - 60;
        elsif tmp >= 50 then c := 5; tmp := tmp - 50;
        elsif tmp >= 40 then c := 4; tmp := tmp - 40;
        elsif tmp >= 30 then c := 3; tmp := tmp - 30;
        elsif tmp >= 20 then c := 2; tmp := tmp - 20;
        elsif tmp >= 10 then c := 1; tmp := tmp - 10;
        end if;
        d1 <= c;

        -- Unidades
        d0 <= tmp;
    end process;
end arch;
