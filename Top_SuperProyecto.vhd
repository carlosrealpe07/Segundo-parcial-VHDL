library ieee;
use ieee.std_logic_1164.all;

entity Top_SuperProyecto is
    port (
        -- 1. Reloj Maestro de 50 MHz (PIN_G21)
        clk_50mhz          : in  std_logic;

        -- 2. Interruptores Deslizables de la placa Altera DE0 (SW[9:0])
        rst_n              : in  std_logic;                    -- SW[0] (PIN_J6): '1'=Operacion, '0'=Reset General
        sw_activar_motor   : in  std_logic;                    -- SW[1] (PIN_H5): '1'=Encender Motor DC, '0'=Frenar
        sw_vel_motor       : in  std_logic_vector(1 downto 0); -- SW[3:2] (PIN_G4, PIN_H6): 4 Velocidades Motor DC
        sw_servo1_man      : in  std_logic;                    -- SW[4] (PIN_G5): Mover Servo 1 manualmente
        sw_servo2_man      : in  std_logic;                    -- SW[5] (PIN_J7): Mover Servo 2 manualmente
        sw_modo_auto       : in  std_logic;                    -- SW[6] (PIN_H7): '1'=Servos automaticos con sensores
        sw_canal_tcs       : in  std_logic_vector(1 downto 0); -- SW[8:7] (PIN_E4, PIN_E3): Canal RGB en displays
        sw_vista_display   : in  std_logic;                    -- SW[9] (PIN_D2): '0'=Ver TCS3200, '1'=Ver HC-SR04

        -- 3. Pines del Conector J5 (GPIO_1) -> COMPONENTE 1: Sensor TCS3200
        tcs_out            : in  std_logic;                    -- Pin 9  de J5 (PIN_AA17)
        tcs_s0             : out std_logic;                    -- Pin 5  de J5 (PIN_AA19)
        tcs_s1             : out std_logic;                    -- Pin 6  de J5 (PIN_AB19)
        tcs_s2             : out std_logic;                    -- Pin 7  de J5 (PIN_AB18)
        tcs_s3             : out std_logic;                    -- Pin 8  de J5 (PIN_AA18)

        -- 4. Pines del Conector J5 (GPIO_1) -> COMPONENTE 2: Sensor HC-SR04
        us_echo            : in  std_logic;                    -- Pin 4  de J5 (PIN_AB20)
        us_trigger         : buffer std_logic;                 -- Pin 2  de J5 (PIN_AA20)

        -- 5. Pines del Conector J5 (GPIO_1) -> COMPONENTE 3: Servomotores SG90
        pwm_servo1         : out std_logic;                    -- Pin 13 de J5 (PIN_Y17)
        pwm_servo2         : out std_logic;                    -- Pin 14 de J5 (PIN_W17)

        -- 6. Pines del Conector J5 (GPIO_1) -> COMPONENTE 4: Motor DC (TB6612)
        pin_pwm            : out std_logic;                    -- Pin 15 de J5 (PIN_U15)
        pin_dir1           : out std_logic;                    -- Pin 16 de J5 (PIN_T15)
        pin_dir2           : out std_logic;                    -- Pin 17 de J5 (PIN_W15)
        pin_standby        : out std_logic;                    -- Pin 18 de J5 (PIN_V15)

        -- 7. Indicadores Visuales en la Placa Altera DE0 (LEDs y 7-Segmentos)
        ledg               : out std_logic_vector(9 downto 0); -- LEDG[9:0]
        hex0               : out std_logic_vector(6 downto 0); -- Display Unidades
        hex1               : out std_logic_vector(6 downto 0); -- Display Decenas
        hex2               : out std_logic_vector(6 downto 0); -- Display Centenas
        hex3               : out std_logic_vector(6 downto 0)  -- Display Letra/Estado
    );
end Top_SuperProyecto;

architecture arch_estructural of Top_SuperProyecto is

    -- Componente 1: Sensor de Color TCS3200
    component Proyecto_TCS3200_Calibrado
        port (
            clk      : in  std_logic;
            rst_n    : in  std_logic;
            sw_canal : in  std_logic_vector(1 downto 0);
            tcs_out  : in  std_logic;
            tcs_s0   : out std_logic;
            tcs_s1   : out std_logic;
            tcs_s2   : out std_logic;
            tcs_s3   : out std_logic;
            leds_rgb : out std_logic_vector(2 downto 0);
            hex0     : out std_logic_vector(6 downto 0);
            hex1     : out std_logic_vector(6 downto 0);
            hex2     : out std_logic_vector(6 downto 0);
            hex3     : out std_logic_vector(6 downto 0)
        );
    end component;

    -- Componente 2: Sensor Ultrasonico HC-SR04
    component HCSR04
        port (
            clk           : in     std_logic;
            echo          : in     std_logic;
            Trigger       : buffer std_logic;
            display_out   : out    std_logic_vector(6 downto 0);
            display_out2  : out    std_logic_vector(6 downto 0);
            transistor    : out    std_logic_vector(3 downto 0);
            presencia     : out    std_logic;
            tamano        : out    std_logic;
            tamano_valido : out    std_logic
        );
    end component;

    -- Componente 3: Servomotores SG90 Opuestos
    component top_servos_opuestos
        port (
            clk        : in  std_logic;
            rst_n      : in  std_logic;
            sw_servo1  : in  std_logic;
            sw_servo2  : in  std_logic;
            pwm_servo1 : out std_logic;
            pwm_servo2 : out std_logic
        );
    end component;

    -- Componente 4: Motor DC con Driver TB6612
    component Control_Cinta_Motor
        port (
            reloj_50mhz        : in  std_logic;
            reset_sistema      : in  std_logic;
            activar_giro       : in  std_logic;
            nivel_velocidad    : in  std_logic_vector(1 downto 0);
            pin_pwm            : out std_logic;
            pin_dir1, pin_dir2 : out std_logic;
            pin_standby        : out std_logic;
            led_funcionamiento : out std_logic
        );
    end component;

    signal rst_alto                         : std_logic;
    signal w_leds_rgb                       : std_logic_vector(2 downto 0);
    signal tcs_h0, tcs_h1, tcs_h2, tcs_h3   : std_logic_vector(6 downto 0);

    signal us_h0, us_h1                     : std_logic_vector(6 downto 0);
    signal w_transistor_dummy               : std_logic_vector(3 downto 0);
    signal w_presencia, w_tamano, w_valido  : std_logic;

    signal w_color_ok                       : std_logic;
    signal act_servo1, act_servo2           : std_logic;
    signal w_led_motor                      : std_logic;

begin

    rst_alto <= not rst_n;

    -- INSTANCIA 1: SENSOR DE COLOR TCS3200
    U1_TCS3200 : Proyecto_TCS3200_Calibrado
        port map (
            clk      => clk_50mhz,
            rst_n    => rst_n,
            sw_canal => sw_canal_tcs,
            tcs_out  => tcs_out,
            tcs_s0   => tcs_s0,
            tcs_s1   => tcs_s1,
            tcs_s2   => tcs_s2,
            tcs_s3   => tcs_s3,
            leds_rgb => w_leds_rgb,
            hex0     => tcs_h0,
            hex1     => tcs_h1,
            hex2     => tcs_h2,
            hex3     => tcs_h3
        );

    -- INSTANCIA 2: SENSOR ULTRASONICO HC-SR04
    U2_HCSR04 : HCSR04
        port map (
            clk           => clk_50mhz,
            echo          => us_echo,
            Trigger       => us_trigger,
            display_out   => us_h0,
            display_out2  => us_h1,
            transistor    => w_transistor_dummy,
            presencia     => w_presencia,
            tamano        => w_tamano,
            tamano_valido => w_valido
        );

    -- LOGICA DE DISPARO DE SERVOS
    w_color_ok <= w_leds_rgb(0) or w_leds_rgb(1) or w_leds_rgb(2);

    act_servo1 <= sw_servo1_man or (sw_modo_auto and w_presencia and w_valido and (not w_tamano) and w_color_ok);
    act_servo2 <= sw_servo2_man or (sw_modo_auto and w_presencia and w_valido and w_tamano and w_color_ok);

    -- INSTANCIA 3: SERVOMOTORES SG90 (GIROS OPUESTOS)
    U3_SERVOS : top_servos_opuestos
        port map (
            clk        => clk_50mhz,
            rst_n      => rst_n,
            sw_servo1  => act_servo1,
            sw_servo2  => act_servo2,
            pwm_servo1 => pwm_servo1,
            pwm_servo2 => pwm_servo2
        );

    -- INSTANCIA 4: MOTOR DC CON PUENTE H TB6612FNG
    U4_MOTOR_DC : Control_Cinta_Motor
        port map (
            reloj_50mhz        => clk_50mhz,
            reset_sistema      => rst_alto,
            activar_giro       => sw_activar_motor,
            nivel_velocidad    => sw_vel_motor,
            pin_pwm            => pin_pwm,
            pin_dir1           => pin_dir1,
            pin_dir2           => pin_dir2,
            pin_standby        => pin_standby,
            led_funcionamiento => w_led_motor
        );

    -- MULTIPLEXOR VISUAL DE LOS 4 DISPLAYS DE 7 SEGMENTOS (SW[9])
    -- SW[9] = '0' -> Muestra Sensor de Color TCS3200
    -- SW[9] = '1' -> Muestra Sensor Ultrasonico HC-SR04
    hex0 <= tcs_h0 when sw_vista_display = '0' else us_h0;
    hex1 <= tcs_h1 when sw_vista_display = '0' else us_h1;
    hex2 <= tcs_h2 when sw_vista_display = '0' else "1111111";
    hex3 <= tcs_h3 when sw_vista_display = '0' else "1111111";

    -- MAPEO DE LOS 10 LEDS VERDES DE LA PLACA ALTERA DE0 (LEDG[9:0])
    ledg(2 downto 0) <= w_leds_rgb;   -- LEDG[0]=Rojo, LEDG[1]=Verde, LEDG[2]=Azul (TCS3200)
    ledg(3)          <= w_presencia;  -- LEDG[3]=Objeto detectado (HC-SR04)
    ledg(4)          <= w_tamano;     -- LEDG[4]=Tamano ('0'=4cm, '1'=8cm)
    ledg(5)          <= w_valido;     -- LEDG[5]=Medida ultrasonica valida (4cm u 8cm)
    ledg(6)          <= act_servo1;   -- LEDG[6]=Testigo Servo 1 activado
    ledg(7)          <= act_servo2;   -- LEDG[7]=Testigo Servo 2 activado
    ledg(8)          <= sw_modo_auto; -- LEDG[8]=Testigo Modo Automatico activo
    ledg(9)          <= w_led_motor;  -- LEDG[9]=Testigo Motor DC en marcha

end arch_estructural;