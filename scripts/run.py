from vunit import VUnit
from itertools import product
# import os
# os.environ["VUNIT_SIMULATOR"] = "ghdl"

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

# Add library uvvm_util
uvvm_util = vu.add_library("uvvm_util")
uvvm_util.add_source_files("../lib/UVVM/uvvm_util/src/*.vhd")

# Add library uvvm_vvc_framework
uvvm_vvc_framework = vu.add_library("uvvm_vvc_framework")
uvvm_vvc_framework.add_source_files("../lib/UVVM/uvvm_vvc_framework/src/*.vhd")

# Add library bitvis_vip_scoreboard
bitvis_vip_scoreboard = vu.add_library("bitvis_vip_scoreboard")
bitvis_vip_scoreboard.add_source_files("../lib/UVVM/bitvis_vip_scoreboard/src/*.vhd")

# Add library bitvis_vip_axistream
bitvis_vip_axistream = vu.add_library("bitvis_vip_axistream")
bitvis_vip_axistream.add_source_files("../lib/UVVM/bitvis_vip_axistream/src/*.vhd")
bitvis_vip_axistream.add_source_files("../lib/UVVM/uvvm_vvc_framework/src_target_dependent/*.vhd")

# Add library bitvis_vip_uart
bitvis_vip_uart = vu.add_library("bitvis_vip_uart")
bitvis_vip_uart.add_source_files("../lib/UVVM/bitvis_vip_uart/src/*.vhd")
bitvis_vip_uart.add_source_files("../lib/UVVM/uvvm_vvc_framework/src_target_dependent/*.vhd")

# Add library lib
lib = vu.add_library("lib")
lib.add_source_files("../src/*.vhd")
lib.add_source_files("../tb/*.vhd")

# Adding test cases with different generics
multi_word_transmission = lib.test_bench("uart_vvc_tb").test("multi_word_transmission")
for baud, clk in product([57600, 115200], [100000000, 10000000]):
  multi_word_transmission.add_config(
    name=f"baud={baud}.clk={clk}",
    generics=dict(GC_BAUDRATE=baud, GC_CLK_FREQ=clk),
  )

# If using GHDL, setting the -frelaxed-rules compile flag
#vu.set_compile_option("ghdl.a_flags", ["-frelaxed-rules"])
#vu.set_sim_option("ghdl.elab_flags", ["-frelaxed-rules"])

# Run vunit function
vu.main()
