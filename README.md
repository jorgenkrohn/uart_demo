# uart_demo
Example design using UVVM and VUnit. Inspired by https://github.com/svnesbo/axistream_uart

# Prerequisites

- A simulator supported by VUnit (ModelSim/Questa, GHDL, NVC, Active-HDL, Riviera-PRO)
- VUnit must be installed. `pip install vunit_hdl`

# Running simulation

Simulation is run by running /scripts/run.py

# Branches
- `main` branch contains a simple non self-checking testbench
- `bfm` branch contains a testbench using UVVM BFM packages
- `vvc` branch contains a testbench using UVVM VVCs
- `vvc_nobugs` branch contains a testbench using UVVM VVCs, but with no bugs in the code

# Excercise 
There are one or more bugs in the code!
Try to find them by first running from `main`, then from `bfm` and then from `vvc`
