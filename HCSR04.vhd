library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity HCSR04 is
    generic (n: integer := 20);
    Port (
        clk           : in     STD_LOGIC;
        echo          : in     STD_LOGIC;
        Trigger       : buffer STD_LOGIC;
        display_out   : out    STD_LOGIC_VECTOR (6 downto 0); -- Unidades (HEX0)
        display_out2  : out    STD_LOGIC_VECTOR (6 downto 0); -- Decenas  (HEX1)
        transistor    : out    STD_LOGIC_VECTOR (3 downto 0);
        presencia     : out    STD_LOGIC; -- '1' = hay objeto, '0' = banda vacia
        tamano        : out    STD_LOGIC; -- '0' = cubo 4cm,   '1' = cubo 8cm
        tamano_valido : out    STD_LOGIC  -- '1' = 4cm u 8cm,  '0' = error/vacio
    );
end HCSR04;

architecture Behavioral of HCSR04 is

    COMPONENT TriggerGen
        PORT(
            clk     : IN  std_logic;
            trigger : OUT std_logic
        );
    END COMPONENT;

    COMPONENT counter
        PORT(
            clk    : IN  std_logic;
            reset  : IN  std_logic;
            enable : IN  std_logic;
            q      : OUT std_logic_vector(19 downto 0)
        );
    END COMPONENT;

    COMPONENT distance_calculation
        PORT(
            echo_count : IN  std_logic_vector(19 downto 0);
            distance   : OUT std_logic_vector(8 downto 0)
        );
    END COMPONENT;

    COMPONENT display_decoder
        PORT(
            distance_in1 : IN  std_logic_vector(8 downto 0);
            display_sal  : OUT std_logic_vector(6 downto 0);
            display_sal2 : OUT STD_LOGIC_VECTOR (6 downto 0)
        );
    END COMPONENT;

    signal Trigger_out             : std_logic;
    signal echo_sync1, echo_sync2  : std_logic := '0';
    signal echo_counter1           : STD_LOGIC_VECTOR (19 downto 0);
    signal echo_count              : STD_LOGIC_VECTOR (19 downto 0) := (others => '0');
    signal distance_bits           : std_logic_vector(8 downto 0);

begin

    transistor <= "1111";

    -- Sincronizador de doble etapa para el pin echo y captura en flanco de bajada
    process(clk)
    begin
        if rising_edge(clk) then
            echo_sync1 <= echo;
            echo_sync2 <= echo_sync1;
            -- Cuando echo pasa de '1' a '0', guardamos el conteo limpio
            if (echo_sync2 = '1' and echo_sync1 = '0') then
                echo_count <= echo_counter1;
            end if;
        end if;
    end process;

    Inst_counter: counter PORT MAP(
        clk,
        Trigger_out,
        echo_sync1,
        echo_counter1
    );

    Inst_TriggerGen: TriggerGen PORT MAP(
        clk,
        Trigger_out
    );

    Inst_distance_calculation: distance_calculation PORT MAP(
        echo_count,
        distance_bits
    );

    Inst_display_decoder: display_decoder PORT MAP(
        distance_bits,
        display_out,
        display_out2
    );

    Trigger <= Trigger_out;

    presencia     <= '0' when distance_bits = "000000000" else '1';
    tamano        <= '1' when distance_bits = "000001000" else '0';
    tamano_valido <= '1' when (distance_bits = "000001000" or distance_bits = "000000100") else '0';

end Behavioral;