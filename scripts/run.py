from vunit import VUnit

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

# Add library lib
lib = vu.add_library("lib")
lib.add_source_files("../src/*.vhd")
lib.add_source_files("../tb/*.vhd")

# Run vunit function
vu.main()
