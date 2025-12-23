# Simple Vivado Project Setup - Manual File Addition
# Run this in Vivado Tcl Shell after cd to project directory

# Step 1: Create project in C:/Temp/mips_vivado
create_project mips_pipeline C:/Temp/mips_vivado -part xc7a35tcpg236-1 -force

puts "Project created! Now add files manually:"
puts "1. Click 'Add Sources' in Flow Navigator"
puts "2. Select 'Add or create design sources'"
puts "3. Navigate to your project folder and add all .v files"
puts ""
puts "Or use File > Add Sources in the menu"
