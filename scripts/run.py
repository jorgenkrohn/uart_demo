from vunit import VUnit
# import os
# os.environ["VUNIT_SIMULATOR"] = "ghdl"

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

# Add library uvvm_util
uvvm_util = vu.add_library("uvvm_util")
uvvm_util.add_source_files("../lib/UVVM/uvvm_util/src/*.vhd")

# Add library bitvis_vip_axistream
bitvis_vip_axistream = vu.add_library("bitvis_vip_axistream")
bitvis_vip_axistream.add_source_files("../lib/UVVM/bitvis_vip_axistream/src/axistream_bfm_pkg.vhd")

# Add library bitvis_vip_uart
bitvis_vip_uart = vu.add_library("bitvis_vip_uart")
bitvis_vip_uart.add_source_files("../lib/UVVM/bitvis_vip_uart/src/uart_bfm_pkg.vhd")

# Add library lib
lib = vu.add_library("lib")
lib.add_source_files("../src/*.vhd")
lib.add_source_files("../tb/*.vhd")

# If using GHDL, setting the -frelaxed-rules compile flag
#vu.set_compile_option("ghdl.a_flags", ["-frelaxed-rules"])
#vu.set_sim_option("ghdl.elab_flags", ["-frelaxed-rules"])

# Run vunit function
vu.main()
