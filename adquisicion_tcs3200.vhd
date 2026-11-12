library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adquisicion_tcs3200 is
    port (
        clk       : in  std_logic; -- Reloj 50 MHz
        rst_n     : in  std_logic; -- Reset activo en bajo
        tcs_out   : in  std_logic; -- Frecuencia del sensor
        
        -- Pines de control hacia el TCS3200
        tcs_s0    : out std_logic;
        tcs_s1    : out std_logic;
        tcs_s2    : out std_logic;
        tcs_s3    : out std_logic;
        
        -- Valores enteros (0 a 999) para el clasificador
        val_r     : out integer range 0 to 999;
        val_g     : out integer range 0 to 999;
        val_b     : out integer range 0 to 999;
        listo     : out std_logic;
        
        -- Salidas BCD para monitoreo en displays (000 a 999)
        r_cen, r_dec, r_uni : out std_logic_vector(3 downto 0);
        g_cen, g_dec, g_uni : out std_logic_vector(3 downto 0);
        b_cen, b_dec, b_uni : out std_logic_vector(3 downto 0)
    );
end adquisicion_tcs3200;

architecture arch_adquisicion of adquisicion_tcs3200 is

    signal sync1, sync2 : std_logic := '0';
    signal flanco_pulso : std_logic;

    type state_type is (s_Rojo, s_Verde, s_Azul, s_FinCiclo);
    signal state : state_type := s_Rojo;

    -- Ventana de 25 ms (1,250,000 ciclos a 50 MHz)
    constant C_VENTANA : integer := 1250000;
    signal cnt_tiempo  : integer range 0 to C_VENTANA := 0;

    signal cnt_int     : integer range 0 to 999 := 0;
    signal c_cen, c_dec, c_uni : unsigned(3 downto 0) := "0000";

begin

    -- Escala de frecuencia al 20%
    tcs_s0 <= '1';
    tcs_s1 <= '0';

    -- Sincronizador de doble etapa para tcs_out
    process(clk, rst_n)
    begin
        if (rst_n = '0') then
            sync1 <= '0';
            sync2 <= '0';
        elsif rising_edge(clk) then
            sync1 <= tcs_out;
            sync2 <= sync1;
        end if;
    end process;

    flanco_pulso <= sync1 and (not sync2);

    -- Maquina de Estados de adquisicion directa (sin dividir pulsos)
    process(clk, rst_n)
    begin
        if (rst_n = '0') then
            state      <= s_Rojo;
            cnt_tiempo <= 0;
            cnt_int    <= 0;
            c_cen      <= "0000"; c_dec <= "0000"; c_uni <= "0000";
            r_cen      <= "0000"; r_dec <= "0000"; r_uni <= "0000";
            g_cen      <= "0000"; g_dec <= "0000"; g_uni <= "0000";
            b_cen      <= "0000"; b_dec <= "0000"; b_uni <= "0000";
            val_r      <= 0; val_g <= 0; val_b <= 0;
            listo      <= '0';

        elsif rising_edge(clk) then
            listo <= '0';

            case state is
                when s_Rojo =>
                    if (cnt_tiempo < C_VENTANA) then
                        cnt_tiempo <= cnt_tiempo + 1;
                        if (cnt_tiempo > 10000 and flanco_pulso = '1') then
                            if (cnt_int < 999) then
                                cnt_int <= cnt_int + 1;
                                if (c_uni = 9) then
                                    c_uni <= "0000";
                                    if (c_dec = 9) then c_dec <= "0000"; c_cen <= c_cen + 1;
                                    else c_dec <= c_dec + 1; end if;
                                else c_uni <= c_uni + 1; end if;
                            end if;
                        end if;
                    else
                        r_cen <= std_logic_vector(c_cen);
                        r_dec <= std_logic_vector(c_dec);
                        r_uni <= std_logic_vector(c_uni);
                        val_r <= cnt_int;
                        cnt_tiempo <= 0; cnt_int <= 0;
                        c_cen <= "0000"; c_dec <= "0000"; c_uni <= "0000";
                        state <= s_Verde;
                    end if;

                when s_Verde =>
                    if (cnt_tiempo < C_VENTANA) then
                        cnt_tiempo <= cnt_tiempo + 1;
                        if (cnt_tiempo > 10000 and flanco_pulso = '1') then
                            if (cnt_int < 999) then
                                cnt_int <= cnt_int + 1;
                                if (c_uni = 9) then
                                    c_uni <= "0000";
                                    if (c_dec = 9) then c_dec <= "0000"; c_cen <= c_cen + 1;
                                    else c_dec <= c_dec + 1; end if;
                                else c_uni <= c_uni + 1; end if;
                            end if;
                        end if;
                    else
                        g_cen <= std_logic_vector(c_cen);
                        g_dec <= std_logic_vector(c_dec);
                        g_uni <= std_logic_vector(c_uni);
                        val_g <= cnt_int;
                        cnt_tiempo <= 0; cnt_int <= 0;
                        c_cen <= "0000"; c_dec <= "0000"; c_uni <= "0000";
                        state <= s_Azul;
                    end if;

                when s_Azul =>
                    if (cnt_tiempo < C_VENTANA) then
                        cnt_tiempo <= cnt_tiempo + 1;
                        if (cnt_tiempo > 10000 and flanco_pulso = '1') then
                            if (cnt_int < 999) then
                                cnt_int <= cnt_int + 1;
                                if (c_uni = 9) then
                                    c_uni <= "0000";
                                    if (c_dec = 9) then c_dec <= "0000"; c_cen <= c_cen + 1;
                                    else c_dec <= c_dec + 1; end if;
                                else c_uni <= c_uni + 1; end if;
                            end if;
                        end if;
                    else
                        b_cen <= std_logic_vector(c_cen);
                        b_dec <= std_logic_vector(c_dec);
                        b_uni <= std_logic_vector(c_uni);
                        val_b <= cnt_int;
                        cnt_tiempo <= 0; cnt_int <= 0;
                        c_cen <= "0000"; c_dec <= "0000"; c_uni <= "0000";
                        state <= s_FinCiclo;
                    end if;

                when s_FinCiclo =>
                    listo <= '1';
                    state <= s_Rojo;

                when others =>
                    state <= s_Rojo;
            end case;
        end if;
    end process;

    -- Control fisico de los filtros S2 y S3
    process(state)
    begin
        case state is
            when s_Rojo  => tcs_s2 <= '0'; tcs_s3 <= '0'; -- Filtro Rojo
            when s_Verde => tcs_s2 <= '1'; tcs_s3 <= '1'; -- Filtro Verde
            when s_Azul  => tcs_s2 <= '0'; tcs_s3 <= '1'; -- Filtro Azul
            when others  => tcs_s2 <= '0'; tcs_s3 <= '0';
        end case;
    end process;

end arch_adquisicion;