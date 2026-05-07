-- =============================================================================
-- TOP: Top Entity
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
        HEX0          : out STD_LOGIC_VECTOR(6 downto 0);
        HEX1          : out STD_LOGIC_VECTOR(6 downto 0);
        HEX2          : out STD_LOGIC_VECTOR(6 downto 0);
        HEX3          : out STD_LOGIC_VECTOR(6 downto 0);
        HEX4          : out STD_LOGIC_VECTOR(6 downto 0);
        HEX5          : out STD_LOGIC_VECTOR(6 downto 0)
    );
end entity top_entity;

architecture structural of top_entity is

    component pc is
        port (clk : in  STD_LOGIC;
              rst : in  STD_LOGIC;
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

    component register_file is
        port (clk    : in  STD_LOGIC;
              rst_rf : in  STD_LOGIC;
              we     : in  STD_LOGIC;
              rs1    : in  STD_LOGIC_VECTOR(4 downto 0);
              rs2    : in  STD_LOGIC_VECTOR(4 downto 0);
              rd     : in  STD_LOGIC_VECTOR(4 downto 0);
              wd     : in  STD_LOGIC_VECTOR(31 downto 0);
              rd1    : out STD_LOGIC_VECTOR(31 downto 0);
              rd2    : out STD_LOGIC_VECTOR(31 downto 0));
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

    -- Señales de control
    signal rst        : STD_LOGIC;
    signal cpu_enable : STD_LOGIC;
    signal clk_div    : unsigned(25 downto 0) := (others => '0');
    signal clk_cpu    : STD_LOGIC := '0';
    signal we_gated   : STD_LOGIC;

    -- Datapath
    signal pc_out     : STD_LOGIC_VECTOR(31 downto 0);
    signal pc_next    : STD_LOGIC_VECTOR(31 downto 0);  
    signal instr      : STD_LOGIC_VECTOR(31 downto 0);
    signal rd1, rd2   : STD_LOGIC_VECTOR(31 downto 0);
    signal alu_res    : STD_LOGIC_VECTOR(31 downto 0);
    signal wb_data    : STD_LOGIC_VECTOR(31 downto 0);
    signal reg_w      : STD_LOGIC;
    signal alu_ctrl   : STD_LOGIC_VECTOR(3 downto 0);
    signal is_jal     : STD_LOGIC;
    signal jal_offset : STD_LOGIC_VECTOR(31 downto 0);
    signal jal_target : STD_LOGIC_VECTOR(31 downto 0);

    -- Display
    signal x_display   : integer range 0 to 999 := 0;
    signal y_display   : integer range 0 to 999 := 0;
    signal x_d2, x_d1, x_d0 : integer range 0 to 9;
    signal y_d2, y_d1, y_d0 : integer range 0 to 9;

    signal alu_res_reg : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal instr_reg   : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal reg_w_reg   : STD_LOGIC := '0';
    signal rd1_reg     : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

    -- Reset sincronizado para evitar problemas al soltar el botón
    signal rst_sync    : STD_LOGIC := '0';
    signal rst_meta    : STD_LOGIC := '0';

begin
    -- Reset activo en bajo
    rst <= not KEY(0);

    process(MAX10_CLK1_50, rst)
    begin
        if rst = '1' then
            rst_meta <= '1';
            rst_sync <= '1';
        elsif rising_edge(MAX10_CLK1_50) then
            rst_meta <= '0';
            rst_sync <= rst_meta;
        end if;
    end process;

    process(MAX10_CLK1_50, rst_sync)
    begin
        if rst_sync = '1' then
            clk_div <= (others => '0');
            clk_cpu <= '0';
        elsif rising_edge(MAX10_CLK1_50) then
            clk_div <= clk_div + 1;
            if SW(0) = '0' then
                clk_cpu <= clk_div(25);
            else
                clk_cpu <= clk_div(22);
            end if;
        end if;
    end process;

    cpu_enable <= '1' when SW(1) = '0' else '0';
    we_gated   <= reg_w and cpu_enable;

    jal_offset <= (instr(31) & instr(31) & instr(31) & instr(31) &
                   instr(31) & instr(31) & instr(31) & instr(31) &
                   instr(31) & instr(31) & instr(31) & instr(31) &
                   instr(19 downto 12) &
                   instr(20) &
                   instr(30 downto 21) &
                   '0');

    jal_target <= std_logic_vector(signed(pc_out) + signed(jal_offset));

    process(is_jal, cpu_enable, jal_target, pc_out)
    begin
        if cpu_enable = '0' then
            pc_next <= pc_out;
        elsif is_jal = '1' then
            pc_next <= jal_target;
        else
            pc_next <= std_logic_vector(unsigned(pc_out) + 4);
        end if;
    end process;

    -- Instancias
    U_PC:   pc            port map (clk => clk_cpu, rst => rst_sync,
                                    d   => pc_next, q => pc_out);

    U_ROM:  rom           port map (addr => pc_out, instr => instr);

    U_CTRL: control_unit  port map (op     => instr(6 downto 0),
                                    f7     => instr(31 downto 25),
                                    reg_w  => reg_w,
                                    alu_c  => alu_ctrl,
                                    is_jal => is_jal);

    U_RF:   register_file port map (clk    => clk_cpu,
                                    rst_rf => rst_sync,
                                    we     => we_gated,
                                    rs1    => instr(19 downto 15),
                                    rs2    => instr(24 downto 20),
                                    rd     => instr(11 downto 7),
                                    wd     => wb_data,
                                    rd1    => rd1,
                                    rd2    => rd2);

    U_ALU:  alu           port map (a => rd1, b => rd2,
                                    ctrl => alu_ctrl, res => alu_res);
    wb_data <= alu_res;

    process(clk_cpu, rst_sync)
    begin
        if rst_sync = '1' then
            alu_res_reg <= (others => '0');
            instr_reg   <= (others => '0');
            reg_w_reg   <= '0';
            rd1_reg     <= (others => '0');
        elsif rising_edge(clk_cpu) then
            alu_res_reg <= alu_res;
            instr_reg   <= instr;
            reg_w_reg   <= reg_w;
            rd1_reg     <= rd1;
        end if;
    end process;

    process(clk_cpu, rst_sync)
    begin
        if rst_sync = '1' then
            x_display <= 0;
            y_display <= 0;
        elsif rising_edge(clk_cpu) then
            if cpu_enable = '1' then

                if reg_w_reg = '1'                       and
                   instr_reg(11 downto 7)  = "00101"     and
                   instr_reg(19 downto 15) = "00101"     and
                   instr_reg(24 downto 20) = "00010"     and
                   instr_reg(31 downto 25) = "0000000"   then
                    if to_integer(unsigned(alu_res_reg)) <= 999 then
                        y_display <= to_integer(unsigned(alu_res_reg));
                    else
                        y_display <= 999;
                    end if;
                end if;

                if reg_w_reg = '1'                       and
                   instr_reg(11 downto 7)  = "00011"     and
                   instr_reg(19 downto 15) = "00011"     and
                   instr_reg(24 downto 20) = "00111"     then
                    if to_integer(unsigned(rd1_reg)) <= 999 then
                        x_display <= to_integer(unsigned(rd1_reg));
                    else
                        x_display <= 999;
                    end if;
                end if;

            end if;
        end if;
    end process;

    -- LEDs y displays
    LEDR <= std_logic_vector(to_unsigned(y_display, 10));

    U_BCD_X: bcd_extractor port map (valor => x_display,
                                      d2 => x_d2, d1 => x_d1, d0 => x_d0);
    U_BCD_Y: bcd_extractor port map (valor => y_display,
                                      d2 => y_d2, d1 => y_d1, d0 => y_d0);

    U_HEX5: seg7_decoder port map (digit => x_d2, seg => HEX5);
    U_HEX4: seg7_decoder port map (digit => x_d1, seg => HEX4);
    U_HEX3: seg7_decoder port map (digit => x_d0, seg => HEX3);
    U_HEX2: seg7_decoder port map (digit => y_d2, seg => HEX2);
    U_HEX1: seg7_decoder port map (digit => y_d1, seg => HEX1);
    U_HEX0: seg7_decoder port map (digit => y_d0, seg => HEX0);

end structural;