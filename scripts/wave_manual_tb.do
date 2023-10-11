onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Transmit
add wave -noupdate -radix hexadecimal /uart_manual_tb/i_uart/s_axis_transmit_tdata
add wave -noupdate /uart_manual_tb/i_uart/s_axis_transmit_tvalid
add wave -noupdate /uart_manual_tb/i_uart/s_axis_transmit_tready
add wave -noupdate /uart_manual_tb/i_uart/uart_txd
add wave -noupdate -radix hexadecimal /uart_manual_tb/received_data
add wave -noupdate -divider Receive
add wave -noupdate -radix hexadecimal /uart_manual_tb/transmit_data
add wave -noupdate /uart_manual_tb/i_uart/uart_rxd
add wave -noupdate -radix hexadecimal /uart_manual_tb/i_uart/m_axis_receive_tdata
add wave -noupdate /uart_manual_tb/i_uart/m_axis_receive_tvalid
add wave -noupdate /uart_manual_tb/i_uart/m_axis_receive_tready
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {61949447 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 293
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {174725250 ps}
