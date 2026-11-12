library ieee;
use ieee.std_logic_1164.all;

entity controlador_sg90_base is
    port (
        clk      : in  std_logic; -- Reloj de 50 MHz
        rst_n    : in  std_logic; -- Reset activo en bajo
        activar  : in  std_logic; -- '0' = Posicion inicial, '1' = Girar 180 grados
        dir_giro : in  std_logic; -- '0' = Sentido normal,   '1' = Sentido opuesto
        pwm_out  : out std_logic  -- Senal al cable naranja del servo
    );
end controlador_sg90_base;

architecture arch_sg90 of controlador_sg90_base is

    -- Periodo de 20 ms a 50 MHz = 1,000,000 ciclos (50 Hz)
    constant C_PERIODO : integer := 1000000;

    -- Extremos para forzar el recorrido completo de 180 grados:
    -- Extremo A: 0.6 ms = 30,000 ciclos
    -- Extremo B: 2.4 ms = 120,000 ciclos
    constant C_PULSO_A : integer := 30000;
    constant C_PULSO_B : integer := 120000;

    signal cnt_pwm     : integer range 0 to C_PERIODO := 0;
    signal ancho_pulso : integer range 0 to C_PERIODO := C_PULSO_A;

begin

    -- Logica para invertir el giro dependiendo de 'dir_giro'
    process(activar, dir_giro)
    begin
        if (dir_giro = '0') then
            -- Giro normal: Reposo en A, Activo en B
            if (activar = '1') then 
                ancho_pulso <= C_PULSO_B;
            else 
                ancho_pulso <= C_PULSO_A; 
            end if;
        else
            -- Giro opuesto: Reposo en B, Activo en A
            if (activar = '1') then 
                ancho_pulso <= C_PULSO_A;
            else 
                ancho_pulso <= C_PULSO_B; 
            end if;
        end if;
    end process;

    -- Generador PWM a 50 Hz
    process(clk, rst_n)
    begin
        if (rst_n = '0') then
            cnt_pwm <= 0;
            pwm_out <= '0';
        elsif rising_edge(clk) then
            if (cnt_pwm >= C_PERIODO - 1) then
                cnt_pwm <= 0;
            else
                cnt_pwm <= cnt_pwm + 1;
            end if;

            if (cnt_pwm < ancho_pulso) then
                pwm_out <= '1';
            else
                pwm_out <= '0';
            end if;
        end if;
    end process;

end arch_sg90;