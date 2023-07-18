# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Nicole Narr <narrn@student.ethz.ch>
# Christopher Reinwardt <creinwar@student.ethz.ch>
# Paul Scheffler <paulsc@iis.ee.ethz.ch>
# Alessandro Ottaviano <aottaviano@iis.ee.ethz.ch>

############
# Carfield #
############

CAR_LD_DIR    ?= $(CAR_SW_DIR)/link

RISCV_LDFLAGS ?= $(RISCV_FLAGS) -nostartfiles -Wl,--gc-sections -Wl,) -L$(CHS_LD_DIR) -L$(CAR_LD_DIR)

car-sw-all: car-sw-libs car-sw-tests

.PRECIOUS: %.elf %.dtb
.PHONY: car-sw-all car-sw-libs car-sw-headers car-sw-tests

# Libraries

CAR_SW_INCLUDES    = -I$(CAR_SW_DIR)/include -I$(CAR_SW_DIR)/tests/bare-metal/safed -I$(CHS_SW_DIR)/include $(CHS_SW_DEPS_INCS)
CAR_SW_LIB_SRCS_S  = $(wildcard $(CAR_SW_DIR)/lib/*.S $(CAR_SW_DIR)/lib/**/*.S)
CAR_SW_LIB_SRCS_C  = $(wildcard $(CAR_SW_DIR)/lib/*.c $(CAR_SW_DIR)/lib/**/*.c)
CAR_SW_LIB_SRCS_O  = $(CAR_SW_DEPS_SRCS:.c=.o) $(CAR_SW_LIB_SRCS_S:.S=.o) $(CAR_SW_LIB_SRCS_C:.c=.o)

CAR_SW_LIBS = $(CAR_SW_DIR)/lib/libcarfield.a

$(CAR_SW_DIR)/lib/libcarfield.a: $(CAR_SW_LIB_SRCS_O)
	$(RISCV_AR) $(RISCV_ARFLAGS) -rcsv $@ $^

car-sw-libs: $(CAR_SW_LIBS)

# Compilation

# All objects require up-to-date patches and headers
%.car.o: %.c
	$(RISCV_CC) $(CAR_SW_INCLUDES) $(RISCV_CCFLAGS) -c $< -o $@

%.car.o: %.S
	$(RISCV_CC) $(CAR_SW_INCLUDES) $(RISCV_CCFLAGS) -c $< -o $@

define car_ld_elf_rule
.PRECIOUS: %.car.$(1).elf

%.car.$(1).elf: $$(CAR_LD_DIR)/$(1).ld %.car.o $(CHS_SW_LIBS) $$(CAR_SW_LIBS)
	$$(RISCV_CC) $$(CAR_SW_INCLUDES) -T$$< $$(RISCV_LDFLAGS) -o $$@ $$(filter-out $$<,$$^)
endef

$(foreach link,$(patsubst $(CAR_LD_DIR)/%.ld,%,$(wildcard $(CAR_LD_DIR)/*.ld)),$(eval $(call car_ld_elf_rule,$(link))))

# Tests

CAR_ELFLOAD_BLOCKING_SAFED_SRC_C := $(CAR_SW_DIR)/tests/bare-metal/hostd/safed_offloader_blocking.c
CAR_ELFLOAD_BLOCKING_SAFED_PATH := $(basename $(CAR_ELFLOAD_BLOCKING_SAFED_SRC_C))

CAR_SW_TEST_SRCS_S	= $(wildcard $(CAR_SW_DIR)/tests/bare-metal/hostd/*.S)
CAR_SW_TEST_SRCS_C	= $(filter-out $(CAR_ELFLOAD_BLOCKING_SAFED_SRC_C), $(wildcard $(CAR_SW_DIR)/tests/bare-metal/hostd/*.c))

CAR_SW_TEST_DRAM_DUMP	= $(CAR_SW_TEST_SRCS_S:.S=.car.dram.dump) $(CAR_SW_TEST_SRCS_C:.c=.car.dram.dump)
CAR_SW_TEST_SPM_DUMP	= $(CAR_SW_TEST_SRCS_S:.S=.car.spm.dump)  $(CAR_SW_TEST_SRCS_C:.c=.car.spm.dump)
CAR_SW_TEST_L2_DUMP	= $(CAR_SW_TEST_SRCS_S:.S=.car.l2.dump)   $(CAR_SW_TEST_SRCS_C:.c=.car.l2.dump)
CAR_SW_TEST_SPM_ROMH	= $(CAR_SW_TEST_SRCS_S:.S=.car.rom.memh)  $(CAR_SW_TEST_SRCS_C:.c=.car.rom.memh)
CAR_SW_TEST_SPM_GPTH	= $(CAR_SW_TEST_SRCS_S:.S=.car.gpt.memh)  $(CAR_SW_TEST_SRCS_C:.c=.car.gpt.memh)

car-sw-tests: $(CAR_SW_TEST_DRAM_DUMP) $(CAR_SW_TEST_SPM_DUMP) $(CAR_SW_TEST_L2_DUMP) $(CAR_SW_TEST_SPM_ROMH) $(CAR_SW_TEST_SPM_GPTH) car-sw-offload-tests

#################
# Safety Island #
#################

include $(CAR_SW_DIR)/tests/bare-metal/safed/sw.mk

# Generate ELFs for blocking offload from cheshire. We execute from L2 or dram.
# TODO: Make this generation nicer and using patterns. As of now, it is ugly and inefficient.
car-sw-offload-tests: safed-sw-all
	$(foreach header,$(HEADER_TARGETS), \
		cp $(header) $(CAR_SW_DIR)/tests/bare-metal/safed/payload.h; \
		$(RISCV_CC) $(CAR_SW_INCLUDES) $(RISCV_CCFLAGS) -c $(CAR_ELFLOAD_BLOCKING_SAFED_SRC_C) -o $(CAR_ELFLOAD_BLOCKING_SAFED_PATH).$(basename $(notdir $(header))).car.o; \
		$(RISCV_CC) $(CAR_SW_INCLUDES) -T$(CAR_LD_DIR)/l2.ld $(RISCV_LDFLAGS) -o $(CAR_ELFLOAD_BLOCKING_SAFED_PATH).$(basename $(notdir $(header))).car.l2.elf  $(CAR_ELFLOAD_BLOCKING_SAFED_PATH).$(basename $(notdir $(header))).car.o $(CHS_SW_LIBS) $(CAR_SW_LIBS); \
		$(RISCV_OBJDUMP) -d -S $(CAR_ELFLOAD_BLOCKING_SAFED_PATH).$(basename $(notdir $(header))).car.l2.elf   > $(CAR_ELFLOAD_BLOCKING_SAFED_PATH).$(basename $(notdir $(header))).car.l2.dump; \
		$(RISCV_CC) $(CAR_SW_INCLUDES) -T$(CHS_LD_DIR)/dram.ld $(RISCV_LDFLAGS) -o $(CAR_ELFLOAD_BLOCKING_SAFED_PATH).$(basename $(notdir $(header))).car.dram.elf  $(CAR_ELFLOAD_BLOCKING_SAFED_PATH).$(basename $(notdir $(header))).car.o $(CHS_SW_LIBS) $(CAR_SW_LIBS); \
		$(RISCV_OBJDUMP) -d -S $(CAR_ELFLOAD_BLOCKING_SAFED_PATH).$(basename $(notdir $(header))).car.dram.elf > $(CAR_ELFLOAD_BLOCKING_SAFED_PATH).$(basename $(notdir $(header))).car.dram.dump; \
		$(RM) $(CAR_SW_DIR)/tests/bare-metal/safed/payload.h; \
		$(RM) $(CAR_ELFLOAD_BLOCKING_SAFED_PATH).$(basename $(notdir $(header))).car.o; \
	)
