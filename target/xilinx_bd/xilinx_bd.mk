# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Cyril Koenig <cykoenig@iis.ee.ethz.ch>

BOARD_bd            := vcu128
XILINX_PART_bd      := xcvu37p-fsvh2892-2L-e
XILINX_BOARD_bd     := xilinx.com:vcu128:part0:1.0
XILINX_PORT_bd      := 3232
XILINX_HOST_bd      := bordcomputer
XILINX_FPGA_PATH_bd := xilinx_tcf/Xilinx/091847100638A

out_bd := target/xilinx_bd/out
bit_bd := $(out_bd)/carfield_$(BOARD_bd).bit

# Derive bender args
xilinx_targs_bd = $(xilinx_targs) -t xilinx_bd -t $(BOARD_bd)
xilinx_defs_bd = $(xilinx_defs) -DNO_HYPERBUS=1

# Vivado variables
VIVADOENV_bd :=  BOARD=$(BOARD_bd)         \
                 XILINX_PART=$(XILINX_PART_bd)    \
                 XILINX_BOARD=$(XILINX_BOARD_bd)  \
                 PORT=$(XILINX_PORT_bd)           \
                 HOST=$(XILINX_HOST_bd)           \
                 FPGA_PATH=$(XILINX_FPGA_PATH_bd)

MODE_bd        ?= gui
VIVADOFLAGS_bd := -nojournal

car-xil-bd-all: $(bit_bd)

$(bit_bd): target/xilinx_bd/scripts/add_includes.tcl target/xilinx_bd/carfield_ip/carfield_ip.xpr
	mkdir $(out_bd)
	cd target/xilinx_bd && $(VIVADOENV_bd) $(VIVADO) $(VIVADOFLAGS_bd) -mode $(MODE_bd) -source scripts/run.tcl
	find target/xilinx_bd/carfield_${BOARD_bd} -name "*.bit" | xargs cp $(bit_bd))

target/xilinx_bd/carfield_ip/carfield_ip.xpr: target/xilinx_bd/scripts/add_sources.tcl
	cd target/xilinx_bd && $(VIVADOENV_bd) $(VIVADO) $(VIVADOFLAGS_bd) -mode batch -source scripts/run_carfield_ip.tcl

# Add includes files for block design
target/xilinx_bd/scripts/add_includes.tcl:
	${BENDER} script vivado --only-defines --only-includes $(common_targs) $(xilinx_targs_bd) $(common_defs) $(xilinx_defs_bd) > $@
# Remove ibex's vendored prim includes as they conflict with opentitan's vendored prim includes
	grep -v -P "lowrisc_ip/ip/prim/rtl" $@ > $@-tmp
	mv $@-tmp $@

# Add source files for ip
target/xilinx_bd/scripts/add_sources.tcl: Bender.yml
	$(BENDER) script vivado $(common_targs) $(xilinx_targs_bd) $(common_defs) $(xilinx_defs_bd) > $@
	cp $@ $@.bak
# Remove ibex's vendored prim includes as they conflict with opentitan's vendored prim includes
	grep -v -P "lowrisc_ip/ip/prim/rtl" $@ > $@-tmp
	mv $@-tmp $@
# Override system verilog files
	target/xilinx/scripts/overrides.sh $@
	echo "" >> $@

car-xil-bd-clean:
	cd target/xilinx_bd && rm -rf scripts/add_sources.tcl* *.log *.jou *.str carfield_* *.ltx out

.PHONY: car-xil-bd-all car-xil-bd-clean
