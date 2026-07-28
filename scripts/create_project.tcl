# ---------------------------------------------------------------------------
# Recreates the Vivado project from the sources in this repository.
#
#   vivado -mode batch -source scripts/create_project.tcl
#
# The Vivado project file itself is not committed: it stores absolute paths
# and the originating account ID. Regenerating it from this script keeps the
# repository free of machine-specific data and makes the build reproducible.
#
# NOTE: the four dist_mem_gen IP cores are NOT recreated here (Xilinx IP is
# not redistributed with this repo). Add them via the IP catalog afterwards --
# single-port RAM, depth 16, data width 64, one .coe per instance.
# ---------------------------------------------------------------------------

set proj_name  "cnn_accelerator"
set part       "xc7a100tcsg324-1"
set repo_root  [file normalize [file dirname [info script]]/..]
set build_dir  "$repo_root/build"

file mkdir $build_dir
create_project $proj_name $build_dir -part $part -force

# --- RTL -------------------------------------------------------------------
add_files -norecurse [glob $repo_root/rtl/*.sv]
set_property file_type SystemVerilog [get_files *.sv]

# --- Testbenches -------------------------------------------------------------
# dist_mem_gen_model.sv is excluded here on purpose: it defines modules named
# dist_mem_gen_0..3, which would collide with the real Xilinx IP once that is
# added to the project. Add it to the sim fileset only if you want to simulate
# without generating the IP:
#
#   add_files -fileset sim_1 -norecurse $repo_root/tb/dist_mem_gen_model.sv
#
# scripts/run_sim.sh always includes it, since standalone simulation has no IP.
foreach tb_file [glob $repo_root/tb/*.sv] {
    if {[file tail $tb_file] eq "dist_mem_gen_model.sv"} { continue }
    add_files -fileset sim_1 -norecurse $tb_file
}
set_property file_type SystemVerilog [get_files -of_objects [get_filesets sim_1]]

# --- Constraints -----------------------------------------------------------
# CNN_top.xdc is the active constraint set (clk / rst / start_ext).
# nexys4_constraints.xdc is the generic Digilent board template, kept for
# reference; it is added but disabled so it does not conflict.
add_files -fileset constrs_1 -norecurse $repo_root/constraints/CNN_top.xdc
add_files -fileset constrs_1 -norecurse $repo_root/constraints/nexys4_constraints.xdc
set_property is_enabled false [get_files nexys4_constraints.xdc]

# --- Top modules -----------------------------------------------------------
set_property top top    [get_filesets sources_1]
set_property top tb_top [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts ""
puts "Project created at $build_dir"
puts "Next: add the four dist_mem_gen IP cores and their .coe files,"
puts "      then run synthesis and implementation."
