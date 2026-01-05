# System Clock
create_clock -period 10.000 -name sys_clk [get_ports SYSCLK_I]

# We re not using those clock at same time. Do not make timing calculation between these clock sources
set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks sys_clk] \
    -group [get_clocks -include_generated_clocks clk_out1_clocking_wizard] \
    -group [get_clocks -include_generated_clocks clk_out2_clocking_wizard] \
    -group [get_clocks -include_generated_clocks clk_out3_clocking_wizard] \
    -group [get_clocks -include_generated_clocks clk_out4_clocking_wizard]

# Asynch. inputs
set_false_path -from [get_ports RST_I]
set_false_path -from [get_ports FONT_SEL_I*]
set_false_path -from [get_ports RES_SEL_I*]
set_false_path -from [get_ports UART_RX_I]