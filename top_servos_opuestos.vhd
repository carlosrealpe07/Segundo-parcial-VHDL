library ieee;
use ieee.std_logic_1164.all;

entity top_servos_opuestos is
    port (
        clk        : in  std_logic; -- Reloj 50 MHz (PIN_G21)
        rst_n      : in  std_logic; -- Reset SW[0] (PIN_J6)
        sw_servo1  : in  std_logic; -- Activa Motor 1 (+180 grados)
        sw_servo2  : in  std_logic; -- Activa Motor 2 (-180 grados)
        pwm_servo1 : out std_logic; -- Senal PWM para Motor 1 (Pin 13 de J5)
        pwm_servo2 : out std_logic  -- Senal PWM para Motor 2 (Pin 14 de J5)
    );
end top_servos_opuestos;

architecture estructural of top_servos_opuestos is

    component controlador_sg90_base
        port (
            clk      : in  std_logic;
            rst_n    : in  std_logic;
            activar  : in  std_logic;
            dir_giro : in  std_logic;
            pwm_out  : out std_logic
        );
    end component;

begin

    -- Instancia 1: Gira 180 grados en sentido "Normal"
    U_SERVO_1: controlador_sg90_base
        port map (
            clk      => clk,
            rst_n    => rst_n,
            activar  => sw_servo1,
            dir_giro => '0', 
            pwm_out  => pwm_servo1
        );

    -- Instancia 2: Gira 180 grados en sentido "Opuesto"
    U_SERVO_2: controlador_sg90_base
        port map (
            clk      => clk,
            rst_n    => rst_n,
            activar  => sw_servo2,
            dir_giro => '1', 
            pwm_out  => pwm_servo2
        );

end estructural;