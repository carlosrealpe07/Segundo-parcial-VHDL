library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Control_Cinta_Motor is
    Port ( 
        reloj_50mhz        : in  STD_LOGIC;
        reset_sistema      : in  STD_LOGIC; -- Activo en alto ('1' = Reset, '0' = Normal)
        activar_giro       : in  STD_LOGIC; -- Switch SW[1] ('1'=On, '0'=Off)
        nivel_velocidad    : in  STD_LOGIC_VECTOR (1 downto 0); -- SW[3:2] Velocidad
        
        -- Salidas al puente H (TB6612) en J5 (GPIO_1)
        pin_pwm            : out STD_LOGIC;
        pin_dir1, pin_dir2 : out STD_LOGIC;
        pin_standby        : out STD_LOGIC;
        
        -- LED indicador
        led_funcionamiento : out STD_LOGIC
    );
end Control_Cinta_Motor;

architecture Arq_Controlador of Control_Cinta_Motor is

    -- Frecuencia PWM = 1 kHz (50,000 ciclos a 50 MHz)
    constant LIMITE_CUENTA_PWM : integer := 49999;
    
    signal registro_contador    : integer range 0 to LIMITE_CUENTA_PWM := 0;
    signal limite_ciclo_trabajo : integer range 0 to 50000 := 0;
    signal s_pwm                : std_logic := '0';

begin

    -- Escalones calibrados para fuente VM = 5.14V (55%, 70%, 85%, 100%)
    with nivel_velocidad select
        limite_ciclo_trabajo <= 27500 when "00", -- 55% (~2.8V al motor)
                                35000 when "01", -- 70% (~3.6V al motor)
                                42500 when "10", -- 85% (~4.4V al motor)
                                50000 when "11", -- 100% (5.14V continuos)
                                50000 when others;

    -- Mantener el chip del motor siempre despierto (3.3V)
    pin_standby <= '1';

    process(reloj_50mhz, reset_sistema)
    begin
        if reset_sistema = '1' then
            registro_contador  <= 0;
            s_pwm              <= '0';
            pin_dir2           <= '0';
            led_funcionamiento <= '0';
            
        elsif rising_edge(reloj_50mhz) then
            if activar_giro = '1' then
                pin_dir2           <= '0';
                led_funcionamiento <= '1';
                
                if registro_contador >= LIMITE_CUENTA_PWM then
                    registro_contador <= 0;
                else
                    registro_contador <= registro_contador + 1;
                end if;
                
                if registro_contador < limite_ciclo_trabajo then
                    s_pwm <= '1';
                else
                    s_pwm <= '0';
                end if;
            else
                pin_dir2           <= '0';
                s_pwm              <= '0';
                led_funcionamiento <= '0';
                registro_contador  <= 0; 
            end if;
        end if;
    end process;

    -- Enviamos el PWM tanto por pin_pwm (Pin 15) como por pin_dir1 (Pin 16)
    -- para garantizar el giro incluso si el Pin 15 de la placa esta danado
    pin_pwm  <= s_pwm;
    pin_dir1 <= s_pwm;

end Arq_Controlador;