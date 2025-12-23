# Vivado Project Setup Script for MIPS Pipeline Processor
# Compatible with Vivado 2022.x / 2024.x
#
# Usage:
#   1. Open Vivado
#   2. In Tcl Console, run: source create_project.tcl
#   3. Or: vivado -mode batch -source create_project.tcl
#
# This script:
#   - Creates a new Vivado project
#   - Adds all Verilog source files
#   - Sets top module and target FPGA
#   - Runs synthesis report

# Project settings
set project_name "mips_pipeline"
set project_dir  "C:/Temp/mips_vivado"
set top_module   "MIPS_Processor"

# Target FPGA (Artix-7 - common on academic boards like Basys3/Nexys4)
# Change this to match your actual hardware
set part_number  "xc7a35tcpg236-1"

# Alternative parts:
# Basys3:     xc7a35tcpg236-1
# Nexys4 DDR: xc7a100tcsg324-1
# Nexys A7:   xc7a100tcsg324-1
# Arty A7:    xc7a35ticsg324-1L

puts "=============================================="
puts "  MIPS Pipeline Processor - Vivado Setup"
puts "=============================================="

# Create project
create_project $project_name $project_dir -part $part_number -force

# Add design sources
puts "\n[Adding Design Sources...]"
add_files -norecurse {
    ./defines.v
    ./topLevelCircuit.v
    ./modules/ALU.v
    ./modules/adder.v
    ./modules/mux.v
    ./modules/register.v
    ./modules/signExtend.v
    ./modules/pipeStages/IFStage.v
    ./modules/pipeStages/IDStage.v
    ./modules/pipeStages/EXEStage.v
    ./modules/pipeStages/MEMStage.v
    ./modules/pipeStages/WBStage.v
    ./modules/pipeRegisters/IF2ID.v
    ./modules/pipeRegisters/ID2EXE.v
    ./modules/pipeRegisters/EXE2MEM.v
    ./modules/pipeRegisters/MEM2WB.v
    ./modules/hazard_forwarding/forwarding.v
    ./modules/hazard_forwarding/hazardDetection.v
    ./modules/controlUnit/controller.v
    ./modules/controlUnit/conditionChecker.v
    ./modules/memoryModules/dataMem.v
    ./modules/memoryModules/instMem.v
    ./modules/memoryModules/registerFile.v
}

# Add SIMD demo sources
puts "[Adding SIMD Demo Sources...]"
add_files -norecurse {
    ./simd_demo/simd_add.v
    ./simd_demo/simd_alu.v
    ./simd_demo/simd_expr_eval.v
}

# Add Branch Prediction sources
puts "[Adding Branch Prediction Sources...]"
add_files -norecurse {
    ./modules/branch_prediction/branch_predictor.v
    ./modules/pipeStages/IFStage_BP.v
}

# Add simulation testbenches
puts "[Adding Simulation Sources...]"
add_files -fileset sim_1 -norecurse {
    ./testbench.v
    ./testbench_metrics.v
    ./testbench_metrics_enhanced.v
    ./simd_demo/tb_simd_add.v
    ./simd_demo/tb_simd_alu.v
    ./simd_demo/tb_simd_expr.v
    ./modules/branch_prediction/tb_branch_predictor.v
}

# Set top module
set_property top $top_module [current_fileset]
set_property top testbench_metrics_enhanced [get_filesets sim_1]

# Include path for defines.v
set_property include_dirs [list "."] [current_fileset]

# Update compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "\n=============================================="
puts "  Project Created Successfully!"
puts "=============================================="
puts ""
puts "Next Steps:"
puts "  1. Run Synthesis:     Run > synth_design"
puts "  2. View Utilization:  Report > Report Utilization"
puts "  3. Run Simulation:    Simulation > Run Simulation"
puts ""
puts "Resource Utilization Report will be generated after synthesis."
puts ""

# Optional: Run synthesis automatically
# Uncomment the following lines to auto-run synthesis
#
# puts "\n[Running Synthesis...]"
# launch_runs synth_1
# wait_on_run synth_1
# open_run synth_1
# report_utilization -file utilization_report.txt
# puts "[Synthesis Complete - Report saved to utilization_report.txt]"
