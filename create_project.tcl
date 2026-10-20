# TCL Script for Vivado Project: Digital FM Modulator on Nexys A7-100T FPGA

set proj_name "FM_Modulator"
set proj_dir  "./vivado_project"
set part_name "xc7a100tcsg324-1"

# Create Vivado project
create_project -force $proj_name $proj_dir -part $part_name
set_property target_language Verilog [current_project]

# Add Top-Level RTL Verilog file
add_files -norecurse ./rtl/FM_Modulator_Top.v

# Import the 6 pre-configured Xilinx IP core (.xci) files
import_ip -files [list \
    ./ip/clk_wiz_0.xci \
    ./ip/dds_compiler_0.xci \
    ./ip/mult_gen_0.xci \
    ./ip/c_addsub_0.xci \
    ./ip/dds_compiler_1.xci \
    ./ip/ila_0.xci \
]

# Add Nexys A7 constraints file (XDC)
add_files -fileset constrs_1 -norecurse ./constraints/FM_constraints.xdc

# Set Top Module and regenerate IP targets
set_property top FM_Modulator_Top [current_fileset]
update_compile_order -fileset sources_1
generate_target all [get_ips]

puts "Project '$proj_name' created successfully!"
puts "Click 'Generate Bitstream' in Flow Navigator to build for Nexys A7."
