# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Valente <luca.valente@unibo.it>
# Alessandro Ottaviano <aottaviano@iis.ee.ethz.ch>
# Yvan Tortorella <yvan.tortorella@unibo.it>

ROOT := .
CHS_ROOT ?= $(ROOT)/cheshire
CAR_SW_DIR := $(ROOT)/sw

BENDER   ?= bender
QUESTA   ?= questa-2022.3
TBENCH   ?= tb_carfield_soc
BOOTMODE ?= 0 # default passive bootmode
PRELMODE ?= 1 # default serial link preload
VOPTARGS ?=

# Include cheshire's makefrag only if the dependency was cloned
-include $(CHS_ROOT)/cheshire.mk

# Spatz 
SPATZ_ROOT ?= $(ROOT)/spatz
SPATZ_MAKEDIR := $(SPATZ_ROOT)/hw/system/spatz_cluster

TESTNAME ?= helloworld
MEMTYPE  ?= spm
BINARY   ?= $(CHS_ROOT)/sw/tests/$(TESTNAME).$(MEMTYPE).elf
IMAGE    ?=

# bender targets
TARGETS += -t sim
TARGETS += -t rtl
TARGETS += -t cv64a6_imafdcsclic_sv39
TARGETS += -t test
TARGETS += -t cva6
TARGETS += -t integer_cluster
TARGETS += -t cv32e40p_use_ff_regfile
TARGETS += -t spatz
TARGETS += -t simulation

# bender defines
DEFINES += -D FEATURE_ICACHE_STAT
DEFINES += -D PRIVATE_ICACHE
DEFINES += -D HIERARCHY_ICACHE_32BIT
DEFINES += -D TARGET_SPATZ

ifdef gui
	VSIM_FLAG :=
	RUN_AND_EXIT := run -all
else
	VSIM_FLAG := -c
	RUN_AND_EXIT := run -all; exit
endif

######################
# Nonfree components #
######################

CAR_NONFREE_REMOTE ?= git@iis-git.ee.ethz.ch:carfield/carfield-nonfree.git
CAR_NONFREE_COMMIT ?= 6c22cff5b6cde5a7d83a5c1b474c8d35d37fd81c

car-nonfree-init:
	git clone $(CAR_NONFREE_REMOTE) nonfree
	cd nonfree && git checkout $(CAR_NONFREE_COMMIT)

-include nonfree/nonfree.mk

############
# Build SW #
############

include $(CAR_SW_DIR)/sw.mk

##############
# Simulation #
##############

hw/carfield_reg_pkg.sv hw/carfield_reg_top.sv: hw/regs/carfield_regs.hjson
	$(REGGEN) -r $< --outdir $(dir $@)

tb/hyp_vip:
	git clone git@iis-git.ee.ethz.ch:carfield/hyp_vip.git $@

scripts/carfield_compile.tcl:
	$(BENDER) script vsim $(TARGETS) $(DEFINES) --vlog-arg="$(VLOG_ARGS)" > $@
	echo 'vlog "$(CURDIR)/$(CHS_ROOT)/target/sim/src/elfloader.cpp" -ccflags "-std=c++11"' >> $@

car-hw-build: scripts/carfield_compile.tcl
	$(QUESTA) vsim -c -do "source scripts/carfield_compile.tcl; exit"

.PHONY: car-hw-sim
car-hw-sim:
	$(QUESTA) vsim $(VSIM_FLAG) -do "set BOOTMODE $(BOOTMODE); set PRELMODE $(PRELMODE); set BINARY $(BINARY); set VOPTARGS $(VOPTARGS); set IMAGE $(IMAGE); set TESTBENCH $(TBENCH); source scripts/start_carfield.tcl ; add log -r sim:/$(TBENCH)/*; $(RUN_AND_EXIT)"

.PHONY: car-hw-clean
car-hw-clean:
	rm -rf *.ini trace* *.wlf transcript work

.PHONY: car-update-dps
car-update-deps:
	$(BENDER) update

car-init: car-update-deps tb/hyp_vip spatz-init chs-init

spatz-init:
	$(MAKE) -C $(SPATZ_MAKEDIR) -B SPATZ_CLUSTER_CFG=carfield.hjson bootrom

.PHONY: chs-init
chs-init:
	$(MAKE) -B chs-hw-all
	$(MAKE) -B chs-sim-all
	$(MAKE) -B chs-sw-all
