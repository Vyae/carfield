# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Cyril Koenig <cykoenig@iis.ee.ethz.ch>

# Create project
set project carfield_ip

create_project $project ./$project -force -part $::env(XILINX_PART)
set_property XPM_LIBRARIES XPM_MEMORY [current_project]

# set number of threads to 8 (maximum, unfortunately)
set_param general.maxThreads 8

# Define sources
source scripts/add_sources.tcl

# Add constraints
add_files -fileset constrs_1 constraints/ooc_carfield_ip.xdc
set_property USED_IN {synthesis out_of_context} [get_files constraints/ooc_carfield_ip.xdc]
add_files -fileset constrs_1 constraints/carfield_ip.xdc 

# Package IP
set_property top carfield_xilinx_ip [current_fileset]

update_compile_order -fileset sources_1
synth_design -rtl -name rtl_1 -sfcu

ipx::package_project -root_dir ./${project} -vendor ethz.ch -library user -taxonomy /UserIP -set_current true
