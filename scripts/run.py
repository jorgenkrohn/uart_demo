from vunit import VUnit
# import os
# os.environ["VUNIT_SIMULATOR"] = "ghdl"

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

# Add library lib
lib = vu.add_library("lib")
lib.add_source_files("../src/*.vhd")
lib.add_source_files("../tb/*.vhd")

# If using GHDL, setting the -frelaxed-rules compile flag
#vu.set_compile_option("ghdl.a_flags", ["-frelaxed-rules"])
#vu.set_sim_option("ghdl.elab_flags", ["-frelaxed-rules"])

# Run vunit function
vu.main()
