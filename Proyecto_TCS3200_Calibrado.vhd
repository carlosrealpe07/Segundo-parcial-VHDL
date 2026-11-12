library ieee;
use ieee.std_logic_1164.all;

entity Proyecto_TCS3200_Calibrado is
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        sw_canal  : in  std_logic_vector(1 downto 0);
        tcs_out   : in  std_logic;
        tcs_s0    : out std_logic;
        tcs_s1    : out std_logic;
        tcs_s2    : out std_logic;
        tcs_s3    : out std_logic;
        leds_rgb  : out std_logic_vector(2 downto 0);
        hex0      : out std_logic_vector(6 downto 0);
        hex1      : out std_logic_vector(6 downto 0);
        hex2      : out std_logic_vector(6 downto 0);
        hex3      : out std_logic_vector(6 downto 0)
    );
end Proyecto_TCS3200_Calibrado;

architecture arch_estructural of Proyecto_TCS3200_Calibrado is

    component adquisicion_tcs3200
        port (
            clk                 : in  std_logic;
            rst_n               : in  std_logic;
            tcs_out             : in  std_logic;
            tcs_s0, tcs_s1      : out std_logic;
            tcs_s2, tcs_s3      : out std_logic;
            val_r, val_g, val_b : out integer range 0 to 999;
            listo               : out std_logic;
            r_cen, r_dec, r_uni : out std_logic_vector(3 downto 0);
            g_cen, g_dec, g_uni : out std_logic_vector(3 downto 0);
            b_cen, b_dec, b_uni : out std_logic_vector(3 downto 0)
        );
    end component;

    component clasificador_rgb_calibrado
        port (
            clk                 : in  std_logic;
            rst_n               : in  std_logic;
            listo               : in  std_logic;
            val_r, val_g, val_b : in  integer range 0 to 999;
            color_out           : out std_logic_vector(1 downto 0);
            color_valido        : out std_logic
        );
    end component;

    component deco_7seg_color
        port (
            a : in  std_logic_vector(3 downto 0);
            d : out std_logic_vector(6 downto 0)
        );
    end component;

    signal w_val_r, w_val_g, w_val_b : integer range 0 to 999;
    signal w_listo                   : std_logic;
    signal w_color_id                : std_logic_vector(1 downto 0);
    signal w_valido                  : std_logic;

    signal s_r_cen, s_r_dec, s_r_uni : std_logic_vector(3 downto 0);
    signal s_g_cen, s_g_dec, s_g_uni : std_logic_vector(3 downto 0);
    signal s_b_cen, s_b_dec, s_b_uni : std_logic_vector(3 downto 0);

    signal mux_cen, mux_dec, mux_uni : std_logic_vector(3 downto 0);
    signal codigo_letra              : std_logic_vector(3 downto 0);

begin

    U_ADQ : adquisicion_tcs3200
        port map (
            clk     => clk,
            rst_n   => rst_n,
            tcs_out => tcs_out,
            tcs_s0  => tcs_s0,
            tcs_s1  => tcs_s1,
            tcs_s2  => tcs_s2,
            tcs_s3  => tcs_s3,
            val_r   => w_val_r,
            val_g   => w_val_g,
            val_b   => w_val_b,
            listo   => w_listo,
            r_cen   => s_r_cen, r_dec => s_r_dec, r_uni => s_r_uni,
            g_cen   => s_g_cen, g_dec => s_g_dec, g_uni => s_g_uni,
            b_cen   => s_b_cen, b_dec => s_b_dec, b_uni => s_b_uni
        );

    U_CLASIF : clasificador_rgb_calibrado
        port map (
            clk          => clk,
            rst_n        => rst_n,
            listo        => w_listo,
            val_r        => w_val_r,
            val_g        => w_val_g,
            val_b        => w_val_b,
            color_out    => w_color_id,
            color_valido => w_valido
        );

    process(sw_canal, w_color_id, s_r_cen, s_r_dec, s_r_uni, s_g_cen, s_g_dec, s_g_uni, s_b_cen, s_b_dec, s_b_uni)
    begin
        case sw_canal is
            when "00" =>
                mux_cen <= s_r_cen; mux_dec <= s_r_dec; mux_uni <= s_r_uni;
            when "01" =>
                mux_cen <= s_g_cen; mux_dec <= s_g_dec; mux_uni <= s_g_uni;
            when "10" =>
                mux_cen <= s_b_cen; mux_dec <= s_b_dec; mux_uni <= s_b_uni;
            when others =>
                if (w_color_id = "01") then
                    mux_cen <= s_r_cen; mux_dec <= s_r_dec; mux_uni <= s_r_uni;
                elsif (w_color_id = "10") then
                    mux_cen <= s_g_cen; mux_dec <= s_g_dec; mux_uni <= s_g_uni;
                elsif (w_color_id = "11") then
                    mux_cen <= s_b_cen; mux_dec <= s_b_dec; mux_uni <= s_b_uni;
                else
                    mux_cen <= s_g_cen; mux_dec <= s_g_dec; mux_uni <= s_g_uni;
                end if;
        end case;
    end process;

    process(w_color_id)
    begin
        case w_color_id is
            when "01" =>
                codigo_letra <= "1011"; -- 'r' (Rojo)
                leds_rgb     <= "001";  -- LEDG[0]
            when "10" =>
                codigo_letra <= "1100"; -- 'G' (Verde)
                leds_rgb     <= "010";  -- LEDG[1]
            when "11" =>
                codigo_letra <= "1010"; -- 'A' (Azul)
                leds_rgb     <= "100";  -- LEDG[2]
            when others =>
                codigo_letra <= "1101"; -- '-' (Vacio / Negro / Rechazo)
                leds_rgb     <= "000";
        end case;
    end process;

    U_HEX0 : deco_7seg_color port map (a => mux_uni,      d => hex0);
    U_HEX1 : deco_7seg_color port map (a => mux_dec,      d => hex1);
    U_HEX2 : deco_7seg_color port map (a => mux_cen,      d => hex2);
    U_HEX3 : deco_7seg_color port map (a => codigo_letra, d => hex3);

end arch_estructural;