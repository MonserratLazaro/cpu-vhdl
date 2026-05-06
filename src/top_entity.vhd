-- =============================================================================
-- TOP: top_entity
-- Tarjeta: Terasic DE10-Lite (Intel MAX10, 50 MHz)
-- Herramienta: Quartus Prime
--
-- Descripción: El procesador RISC-V calcula y = 3x + 5.
--              Los resultados se muestran en:
--
--   HEX5 HEX4 HEX3  →  valor de X en decimal (3 dígitos)
--   HEX2 HEX1 HEX0  →  valor de Y en decimal (3 dígitos)
--   LEDR[9:0]       →  valor de Y en binario (10 bits)
--
--   Ejemplo para x=5, y=20:
--     HEX5=0, HEX4=0, HEX3=5  (muestra "005")
--     HEX2=0, HEX1=2, HEX0=0  (muestra "020")
--     LEDR = 0000010100        (20 en binario)
--
-- La velocidad de actualización está controlada por un divisor de reloj.
-- KEY[0] = reset  (presionar para reiniciar desde x=0)
-- SW[0]  = velocidad:
--   '0' → lento  (~1 valor por segundo, fácil de leer)
--   '1' → medio  (~6 valores por segundo, ver el patrón)
-- SW[1]  = pausa:
--   '0' → ejecución normal
--   '1' → pausa: congela displays y LEDs en el valor actual
--          al bajar de vuelta a '0' continúa desde donde se pausó
-- =============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_entity is
    port (
        MAX10_CLK1_50 : in  STD_LOGIC;
        KEY           : in  STD_LOGIC_VECTOR(1 downto 0);
        SW            : in  STD_LOGIC_VECTOR(9 downto 0);
        LEDR          : out STD_LOGIC_VECTOR(9 downto 0);
        HEX0          : out STD_LOGIC_VECTOR(6 downto 0);  -- unidades Y
        HEX1          : out STD_LOGIC_VECTOR(6 downto 0);  -- decenas Y
        HEX2          : out STD_LOGIC_VECTOR(6 downto 0);  -- centenas Y
        HEX3          : out STD_LOGIC_VECTOR(6 downto 0);  -- unidades X
        HEX4          : out STD_LOGIC_VECTOR(6 downto 0);  -- decenas X
        HEX5          : out STD_LOGIC_VECTOR(6 downto 0)   -- centenas X
    );
end entity top_entity;

architecture structural of top_entity is

    -- =========================================================================
    -- Componentes
    -- =========================================================================
    component pc is
        port (clk : in  STD_LOGIC; rst : in STD_LOGIC;
              d   : in  STD_LOGIC_VECTOR(31 downto 0);
              q   : out STD_LOGIC_VECTOR(31 downto 0));
    end component;

    component rom is
        port (addr  : in  STD_LOGIC_VECTOR(31 downto 0);
              instr : out STD_LOGIC_VECTOR(31 downto 0));
    end component;

    component control_unit is
        port (op     : in  STD_LOGIC_VECTOR(6 downto 0);
              f7     : in  STD_LOGIC_VECTOR(6 downto 0);
              reg_w  : out STD_LOGIC;
              alu_c  : out STD_LOGIC_VECTOR(3 downto 0);
              is_jal : out STD_LOGIC);
    end component;

    component Register_File is
        port (clk : in  STD_LOGIC; we  : in  STD_LOGIC;
              rs1 : in  STD_LOGIC_VECTOR(4 downto 0);
              rs2 : in  STD_LOGIC_VECTOR(4 downto 0);
              rd  : in  STD_LOGIC_VECTOR(4 downto 0);
              wd  : in  STD_LOGIC_VECTOR(31 downto 0);
              rd1 : out STD_LOGIC_VECTOR(31 downto 0);
              rd2 : out STD_LOGIC_VECTOR(31 downto 0));
    end component;

    component alu is
        port (a, b  : in  STD_LOGIC_VECTOR(31 downto 0);
              ctrl  : in  STD_LOGIC_VECTOR(3 downto 0);
              res   : out STD_LOGIC_VECTOR(31 downto 0));
    end component;

    component seg7_decoder is
        port (digit : in  integer range 0 to 9;
              seg   : out STD_LOGIC_VECTOR(6 downto 0));
    end component;

    component bcd_extractor is
        port (valor : in  integer range 0 to 999;
              d2    : out integer range 0 to 9;
              d1    : out integer range 0 to 9;
              d0    : out integer range 0 to 9);
    end component;

    -- =========================================================================
    -- Señales internas
    -- =========================================================================
    signal rst       : STD_LOGIC;

    -- Divisor de reloj configurable con SW[1:0]
    signal clk_div   : unsigned(25 downto 0) := (others => '0');
    signal clk_cpu   : STD_LOGIC := '0';

    -- Datapath RISC-V
    signal pc_out    : STD_LOGIC_VECTOR(31 downto 0);
    signal pc_next   : STD_LOGIC_VECTOR(31 downto 0);
    signal instr     : STD_LOGIC_VECTOR(31 downto 0);
    signal rd1, rd2  : STD_LOGIC_VECTOR(31 downto 0);
    signal alu_res   : STD_LOGIC_VECTOR(31 downto 0);
    signal wb_data   : STD_LOGIC_VECTOR(31 downto 0);
    signal reg_w     : STD_LOGIC;
    signal alu_ctrl  : STD_LOGIC_VECTOR(3 downto 0);
    signal is_jal    : STD_LOGIC;
    signal jal_offset: STD_LOGIC_VECTOR(31 downto 0);
    signal jal_target: STD_LOGIC_VECTOR(31 downto 0);

    -- Valores capturados de x e y
    signal x_display : integer range 0 to 999 := 0;
    signal y_display : integer range 0 to 999 := 0;

    -- BCD para X
    signal x_d2, x_d1, x_d0 : integer range 0 to 9;
    -- BCD para Y
    signal y_d2, y_d1, y_d0 : integer range 0 to 9;

begin

    -- Reset activo en bajo (KEY[0])
    rst <= not KEY(0);

    -- =========================================================================
    -- Divisor de reloj:
    --   SW[0]='0' → lento  (bit 25, ~0.75 Hz → ~1 valor/seg)
    --   SW[0]='1' → medio  (bit 22, ~6 Hz    → ~6 valores/seg)
    --   SW[1]='1' → pausa: el reloj del CPU se congela en '0'
    --               (el PC no avanza, los registros no cambian,
    --                los displays y LEDs quedan congelados)
    --   SW[1]='0' → ejecución normal, continúa desde donde estaba
    -- =========================================================================
    process(MAX10_CLK1_50, rst)
    begin
        if rst = '1' then
            clk_div <= (others => '0');
            clk_cpu <= '0';
        elsif rising_edge(MAX10_CLK1_50) then
            clk_div <= clk_div + 1;

            if SW(1) = '1' then
                -- PAUSA: detener el reloj del CPU
                clk_cpu <= '0';
            else
                -- EJECUCIÓN: seleccionar velocidad con SW[0]
                if SW(0) = '0' then
                    clk_cpu <= clk_div(25);  -- lento  ~1 valor/seg
                else
                    clk_cpu <= clk_div(22);  -- medio  ~6 valores/seg
                end if;
            end if;
        end if;
    end process;

    -- =========================================================================
    -- Datapath RISC-V
    -- =========================================================================
    jal_offset <= (instr(31) & instr(31) & instr(31) & instr(31) &
                   instr(31) & instr(31) & instr(31) & instr(31) &
                   instr(31) & instr(31) & instr(31) & instr(31) &
                   instr(19 downto 12) &
                   instr(20) &
                   instr(30 downto 21) &
                   '0');

    jal_target <= std_logic_vector(signed(pc_out) + signed(jal_offset));

    pc_next <= jal_target when (is_jal = '1') else
               std_logic_vector(unsigned(pc_out) + 4);

    U_PC:   pc            port map (clk => clk_cpu, rst => rst,
                                    d => pc_next, q => pc_out);
    U_ROM:  rom           port map (addr => pc_out, instr => instr);
    U_CTRL: control_unit  port map (op => instr(6 downto 0),
                                    f7 => instr(31 downto 25),
                                    reg_w => reg_w,
                                    alu_c => alu_ctrl,
                                    is_jal => is_jal);
    U_RF:   Register_File port map (clk => clk_cpu, we => reg_w,
                                    rs1 => instr(19 downto 15),
                                    rs2 => instr(24 downto 20),
                                    rd  => instr(11 downto 7),
                                    wd  => wb_data,
                                    rd1 => rd1, rd2 => rd2);
    U_ALU:  alu           port map (a => rd1, b => rd2,
                                    ctrl => alu_ctrl, res => alu_res);
    wb_data <= alu_res;

    -- =========================================================================
    -- Capturar x e y cuando el procesador escribe en x5 (resultado y)
    -- La instrucción "add x5, x5, x2" escribe en rd = x5 = "00101"
    -- En ese momento: alu_res = y calculada, rd1 = m*x (x5 antes), rd2 = b (x2)
    -- El valor de x está en x3, que es rd1 de la instrucción anterior.
    -- Simplificación: calculamos x e y directamente desde x6 (contador)
    -- =========================================================================
    process(MAX10_CLK1_50, rst)
    begin
        if rst = '1' then
            x_display <= 0;
            y_display <= 0;
        elsif rising_edge(MAX10_CLK1_50) then
            -- Cuando se escribe en x5 ("00101"): ese es el resultado y=mx+b
            if reg_w = '1' and instr(11 downto 7) = "00101" then
                -- alu_res = y = m*x + b
                if to_integer(unsigned(alu_res)) <= 999 then
                    y_display <= to_integer(unsigned(alu_res));
                else
                    y_display <= 999;
                end if;
            end if;
            -- Cuando se escribe en x3 ("00011"): ese es el nuevo x = x+1
            -- Capturamos el valor ANTES de incrementar (rd1 = x3 actual)
            if reg_w = '1' and instr(11 downto 7) = "00011" then
                if to_integer(unsigned(rd1)) <= 999 then
                    x_display <= to_integer(unsigned(rd1));
                else
                    x_display <= 999;
                end if;
            end if;
        end if;
    end process;

    -- =========================================================================
    -- LEDs: valor de Y en binario (10 bits bajos)
    -- =========================================================================
    LEDR <= std_logic_vector(to_unsigned(y_display, 10));

    -- =========================================================================
    -- BCD extractors para X e Y
    -- =========================================================================
    U_BCD_X: bcd_extractor port map (valor => x_display,
                                      d2 => x_d2, d1 => x_d1, d0 => x_d0);
    U_BCD_Y: bcd_extractor port map (valor => y_display,
                                      d2 => y_d2, d1 => y_d1, d0 => y_d0);

    -- =========================================================================
    -- 7 Segmentos
    -- HEX5 HEX4 HEX3 = X (centenas, decenas, unidades)
    -- HEX2 HEX1 HEX0 = Y (centenas, decenas, unidades)
    -- =========================================================================
    U_HEX5: seg7_decoder port map (digit => x_d2, seg => HEX5);
    U_HEX4: seg7_decoder port map (digit => x_d1, seg => HEX4);
    U_HEX3: seg7_decoder port map (digit => x_d0, seg => HEX3);

    U_HEX2: seg7_decoder port map (digit => y_d2, seg => HEX2);
    U_HEX1: seg7_decoder port map (digit => y_d1, seg => HEX1);
    U_HEX0: seg7_decoder port map (digit => y_d0, seg => HEX0);

end structural;
