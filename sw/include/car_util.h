// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Robert Balas <balasr@iis.ee.ethz.ch>
// Alessandro Ottaviano <aottaviano@iis.ee.ethz.ch>

#ifndef __CAR_UTIL_H
#define __CAR_UTIL_H

#include "util.h"
#include "car_memory_map.h"
#include "car_properties.h"
#include "regs/soc_ctrl.h"
#include "io.h"

// execution error codes
#define EHOSTDEXEC  1 // Execution error host domain
#define ESAFEDEXEC  2 // Execution error safe domain
#define EINTCLEXEC  3 // Execution error integer cluster
#define EFPCLEXEC   4 // Execution error floating point cluster
#define EPERIPHEXEC 5 // Execution error peripheral domain
// access error codes
#define EHOSTDNOACCES   6 // Access error in host domain
#define ESAFEDNOACCES   7 // Access error in safe domain
#define EINTCLNOACCES   8 // Access error in integer cluster
#define EFPCLNOACCES    9 // Access error in floating point cluster
#define EPERIPHNOACCES 10 // Access error in peripheral domain

// Clock and reset control

// for the calculation check safety island top
#define SAFETY_ISLAND_BOOT_ADDR_RSVAL (CAR_SAFETY_ISLAND_PERIPHS_BASE_ADDR + 0x1080)

enum car_isolation_status { CAR_ISOLATE_DISABLE = 0, CAR_ISOLATE_ENABLE = 1 };

enum car_rst_status { CAR_RST_ASSERT = 1, CAR_RST_RELEASE = 0 };

// As input clocks for carfield, we have 3 clock sources to be multiplexed among 6 domains.
enum car_src_clk {
    CAR_CLK0 = 0,
    CAR_CLK1 = 1,
    CAR_CLK2 = 2
};

enum car_clk {
    CAR_HOST_CLK     = 0,
    CAR_PERIPH_CLK   = 1,
    CAR_SAFETY_CLK   = 2,
    CAR_SECURITY_CLK = 3,
    CAR_PULP_CLK     = 4,
    CAR_SPATZ_CLK    = 5,
    CAR_L2_CLK       = 6,
};

enum car_rst {
    CAR_PERIPH_RST   = 0,
    CAR_SAFETY_RST   = 1,
    CAR_SECURITY_RST = 2,
    CAR_PULP_RST     = 3,
    CAR_SPATZ_RST    = 4,
    CAR_L2_RST       = 5,
};

#define CARFIELD_HOST_CLK_EN_REG_OFFSET -1
#define CARFIELD_HOST_CLK_SEL_REG_OFFSET -1
#define CARFIELD_HOST_CLK_DIV_VALUE_REG_OFFSET -1

// generate register offset for reset domains from autogenerated soc_ctrl.h
#define X(NAME)                                                                \
    static inline uint32_t car_get_##NAME##_offset(enum car_rst rst)           \
    {                                                                          \
	switch (rst) {                                                         \
	case CAR_PERIPH_RST:                                                   \
	    return CARFIELD_PERIPH_##NAME##_REG_OFFSET;                        \
	case CAR_SAFETY_RST:                                                   \
	    return CARFIELD_SAFETY_ISLAND_##NAME##_REG_OFFSET;                 \
	case CAR_SECURITY_RST:                                                 \
	    return CARFIELD_SECURITY_ISLAND_##NAME##_REG_OFFSET;               \
	case CAR_PULP_RST:                                                     \
	    return CARFIELD_PULP_CLUSTER_##NAME##_REG_OFFSET;                  \
	case CAR_SPATZ_RST:                                                    \
	    return CARFIELD_SPATZ_CLUSTER_##NAME##_REG_OFFSET;                 \
	case CAR_L2_RST:                                                       \
	    return CARFIELD_L2_##NAME##_REG_OFFSET;                            \
	default:                                                               \
	    return -1;                                                         \
	}                                                                      \
    }

X(RST);
X(ISOLATE);
X(ISOLATE_STATUS);
#undef X

// generate register offset for clock domains from autogenerated soc_ctrl.h
#define X(NAME)                                                                \
    static inline uint32_t car_get_##NAME##_offset(enum car_clk clk)           \
    {                                                                          \
	switch (clk) {                                                         \
	case CAR_HOST_CLK:                                                     \
	    return CARFIELD_HOST_##NAME##_REG_OFFSET;                          \
	case CAR_PERIPH_CLK:                                                   \
	    return CARFIELD_PERIPH_##NAME##_REG_OFFSET;                        \
	case CAR_SAFETY_CLK:                                                   \
	    return CARFIELD_SAFETY_ISLAND_##NAME##_REG_OFFSET;                 \
	case CAR_SECURITY_CLK:                                                 \
	    return CARFIELD_SECURITY_ISLAND_##NAME##_REG_OFFSET;               \
	case CAR_PULP_CLK:                                                     \
	    return CARFIELD_PULP_CLUSTER_##NAME##_REG_OFFSET;                  \
	case CAR_SPATZ_CLK:						       \
	    return CARFIELD_SPATZ_CLUSTER_##NAME##_REG_OFFSET;                 \
	case CAR_L2_CLK:                                                       \
	    return CARFIELD_L2_##NAME##_REG_OFFSET;                            \
	default:                                                               \
	    return -1;                                                         \
	}                                                                      \
    }

X(CLK_EN);
X(CLK_SEL);
X(CLK_DIV_VALUE);
#undef X

static inline enum car_clk car_clkd_from_rstd(enum car_rst rst)
{
    switch (rst) {
    case CAR_PERIPH_RST:
	return CAR_PERIPH_CLK;
    case CAR_SAFETY_RST:
	return CAR_SAFETY_CLK;
    case CAR_SECURITY_RST:
	return CAR_SECURITY_CLK;
    case CAR_PULP_RST:
	return CAR_PULP_CLK;
    case CAR_SPATZ_RST:
	return CAR_SPATZ_CLK;
    case CAR_L2_RST:
	return CAR_L2_CLK;
    }
}

void car_set_isolate(enum car_rst rst, enum car_isolation_status status)
{
    writew(status, CAR_SOC_CTRL_BASE_ADDR(base_soc_ctrl) + car_get_ISOLATE_offset(rst));
    fence();
    while (readw(CAR_SOC_CTRL_BASE_ADDR(base_soc_ctrl) + car_get_ISOLATE_STATUS_offset(rst)) !=
	   status)
	;
}

void car_enable_clk(enum car_clk clk)
{
    writew(1, CAR_SOC_CTRL_BASE_ADDR(base_soc_ctrl) + car_get_CLK_EN_offset(clk));
    fence();
}

void car_disable_clk(enum car_clk clk)
{
    writew(0, CAR_SOC_CTRL_BASE_ADDR(base_soc_ctrl) + car_get_CLK_EN_offset(clk));
    fence();
}

void car_select_clk(enum car_src_clk clk_src, enum car_clk clk)
{
    writew(clk_src, CAR_SOC_CTRL_BASE_ADDR(base_soc_ctrl) + car_get_CLK_SEL_offset(clk));
    fence();
}

void car_set_rst(enum car_rst rst, enum car_rst_status status)
{
    writew(status, CAR_SOC_CTRL_BASE_ADDR(base_soc_ctrl) + car_get_RST_offset(rst));
    fence();
}

// SW reset cycle without changing the selected clock source
void car_reset_domain(enum car_rst rst)
{
    car_set_isolate(rst, CAR_ISOLATE_ENABLE);
    car_disable_clk(car_clkd_from_rstd(rst));

    car_set_rst(rst, CAR_RST_ASSERT);
    for (volatile int i = 0; i < 16; i++)
	;
    car_set_rst(rst, CAR_RST_RELEASE);

    car_enable_clk(car_clkd_from_rstd(rst));
    car_set_isolate(rst, CAR_ISOLATE_DISABLE);
}

// Safety Island offload
void prepare_safed_boot () {

	// Select bootmode
	volatile uintptr_t *bootmode_addr = (uintptr_t*)CAR_SAFETY_ISLAND_BOOTMODE_ADDR(base_safety_island);
	writew(1, bootmode_addr);

	// Write entry point into boot address
	volatile uintptr_t *bootaddr_addr = (uintptr_t*)CAR_SAFETY_ISLAND_BOOTADDR_ADDR(base_safety_island);
	writew(CAR_SAFETY_ISLAND_ENTRY_POINT(base_safety_island), bootaddr_addr);

	// Assert fetch enable
	volatile uintptr_t *fetchen_addr = (uintptr_t*)CAR_SAFETY_ISLAND_FETCHEN_ADDR(base_safety_island);
	writew(1, fetchen_addr);

}

uint32_t poll_safed_corestatus () {

	volatile uint32_t corestatus;
	volatile uintptr_t *corestatus_addr = (uintptr_t*)CAR_SAFETY_ISLAND_CORESTATUS_ADDR(base_safety_island);
	// TODO: Add a timeut to not poll indefinitely
	while (((uint32_t)readw(corestatus_addr) & 0x80000000) == 0)
	    ;

	corestatus = (uint32_t) readw(corestatus_addr);

	return corestatus;
}

uint32_t safed_offloader_blocking () {

	uint32_t ret = 0;

	// Load binary payload
	load_binary();

	// Select bootmode, write entry point, write launch signal
	prepare_safed_boot();

	// Poll status register
	volatile uint32_t corestatus = poll_safed_corestatus();

	// Check core status. Return safed exit code to signal an error in the execution.
	if ((corestatus & 0x7FFFFFFF) != 0) {
	    ret = ESAFEDEXEC;
	}

	return ret;
}

// PULP cluster setup and configuration

void pulp_cluster_set_bootaddress(uint32_t pulp_boot_addr) {

  volatile uint32_t cluster_boot_reg_addr = CAR_INT_CLUSTER_BOOT_ADDR_REG;

  for (int i = 0; i < IntClustNumCores; i++) {
    writew(pulp_boot_addr, (uint32_t*)(cluster_boot_reg_addr));
    cluster_boot_reg_addr += 0x4;
  }
}

void pulp_cluster_start() {

  volatile uint32_t *booten_addr = (uint32_t*)(CAR_INT_CLUSTER_BOOTEN_ADDR(base_soc_ctrl));
  writew(1, booten_addr);

  volatile uint32_t *fetchen_addr = (uint32_t*)(CAR_INT_CLUSTER_FETCHEN_ADDR(base_soc_ctrl));
	writew(1, fetchen_addr);
}

void pulp_cluster_wait_eoc() {

  volatile uint32_t *pulp_eoc_addr = (uint32_t*)(CAR_INT_CLUSTER_EOC_ADDR(base_soc_ctrl));

  while(!readw(pulp_eoc_addr))
      ;

}

#endif
