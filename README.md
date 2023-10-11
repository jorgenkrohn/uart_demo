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

There are three bugs in the source code. One can easily be detected by the VVC testbench, one is also easily detected by the BFM testbench and one can easily be detected by all three testbenches.
