# UART VHDL

A VHDL implementation of UART transmit and receive logic. The entities are available in `uart.vhd` and in separate files. `uart_top.vhd` contains a top-level integration example; review its library bindings and connections for your simulator/FPGA project before use.

## Included entities

| Entity | Purpose | Default configuration |
|---|---|---|
| `baud_tick` | Generates a transmit baud tick from the system clock. | 50 MHz clock, 9600 baud |
| `tx` | Loads an 8-bit word and shifts it out least-significant bit first, one bit per baud tick. | 8 data bits |
| `tx_fsm` | Controls the transmit start, data, and stop phases; provides `busy` and `tx_done`. | UART idle line is high |
| `baud_rx` | Generates receiver sample ticks for oversampling. | 50 MHz clock, 9600 baud, 16x oversampling |
| `rx_fsm` | Detects a start bit, samples eight data bits, checks the stop bit, and reports completion or framing error. | 8 data bits, 16 samples per bit |
| `uart_top` | Example top-level integration of transmit and baud-generation blocks. | 50 MHz clock, 9600 baud |

Together, the transmitter and receiver are intended for asynchronous serial communication using a high idle line, a low start bit, eight data bits (least-significant bit first), and a high stop bit (8-N-1 framing).

## Integration overview

- Connect the same clock and active-high synchronous reset to the relevant entities.
- For transmit, connect the `baud_tick` output to both the `tx` datapath and `tx_fsm`; connect `tx_bit` and `done` from `tx` to the matching FSM inputs. The FSM's `load` output drives `tx.load`, while `tx_fsm.tx_out` is the serial output.
- For receive, connect `baud_rx.sample_tick` to `rx_fsm.sample_tick`, and connect the incoming serial wire to `rx_fsm.tx_line` (this port is named `tx_line` in the source even though it is the receiver input).
- Configure matching clock and baud-rate values on both sides. The receiver's oversampling factor is currently set to 16.

## Parameters and notes

- `baud_tick` uses `FREQ` and `BAUDRATE` generics.
- `baud_rx` uses `CLK_FREQ`, `BAUD_RX`, and `OVERSAMPLING_FACT` generics.
- The tick generators use integer division, so choose parameters that provide an acceptable baud-rate/sample-rate approximation.
- `uart_top.vhd` binds entities through the `example3_lib` library name and also exposes baud signals as ports. Adjust library compilation and connections as needed for your toolchain. There is no testbench included; simulate the intended clock, reset, and serial timing before hardware use.
