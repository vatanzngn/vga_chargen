library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ps2kb is
    port(
        clk_i : in std_logic;
        data_i : in std_logic;

        -- indicates we fetched all bits of the key
        rx_ready_o : out std_logic;
        rx_o : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of ps2kb is

    signal parity : std_logic := '0';
    signal cntr : integer range 0 to 15 := 0;
    signal rx_ready : std_logic := '0';
    signal rx_data : std_logic_vector(7 downto 0) := x"00";

begin

    process(clk_i) is begin

        if falling_edge(clk_i) then

            rx_ready_o <= rx_ready;
            rx_o <= rx_data;

            if rx_ready = '1' then
                rx_ready <= '0';
                parity <= '0';
            end if;

            if (cntr = 0 and data_i = '0') or cntr /= 0 then
                cntr <= cntr + 1;
            end if;

            case cntr is
                when 1 to 8 => 
                    rx_data <= data_i & rx_data(7 downto 1);
                    if data_i = '1' then
                        -- the parity will be '1' when the number of ones in the data stream is and odd number, otherwise '0'.
                        -- e.g., for '01001000' parity will be '0'
                        parity <= not(parity);
                    end if;

                when 9 =>
                    -- reuse the parity symbol to indicate the parity check has succeeded.
                    parity <= parity xor data_i;
                
                when 10 =>
                    if parity = '1' and data_i = '1' then
                        rx_ready <= '1';
                    end if;
                    cntr <= 0;

                when others => null;
            end case;

        end if;

    end process;

end architecture;