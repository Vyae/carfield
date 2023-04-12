// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Thomas Benz  <tbenz@ethz.ch>
// Yvan Tortorella <yvan.tortorella@unibo.it>

/// Carfield constants and Cheshire overwrites
package carfield_pkg;

import cheshire_pkg::*;

typedef enum byte_bt {
  L2Port1Idx      = 'd0,
  L2Port2Idx      = 'd1,
  SafetyIslandIdx = 'd2
} axi_idx_t;

typedef enum doub_bt {
  L2Port1Base      = 'h0000_0000_7800_0000,
  L2Port2Base      = 'h0000_0000_7820_0000,
  SafetyIslandBase = 'h0000_0000_6000_0000
} axi_start_t;

typedef enum doub_bt {
  L2Size           = 'h0000_0000_0020_0000,
  SafetyIslandSize = 'h0000_0000_0080_0000
} axi_size_t;

typedef enum doub_bt {
  L2Port1End      = L2Port1Base + L2Size,
  L2Port2End      = L2Port2Base + L2Size,
  SafetyIslandEnd = SafetyIslandBase + SafetyIslandSize
} axi_end_t;

localparam bit [2:0] AxiNumExtSlv = 3'd2 +  3'd1;
                                 // L2Ports Safety Island

localparam cheshire_cfg_t CarfieldCfgDefault = '{
  // CVA6 parameters
  Cva6RASDepth      : ariane_pkg::ArianeDefaultConfig.RASDepth,
  Cva6BTBEntries    : ariane_pkg::ArianeDefaultConfig.BTBEntries,
  Cva6BHTEntries    : ariane_pkg::ArianeDefaultConfig.BHTEntries,
  Cva6NrPMPEntries  : 0,
  Cva6ExtCieLength  : 'h2000_0000,
  // Harts
  DualCore          : 0,  // Only one core, but rest of config allows for two
  CoreMaxTxnsPerId  : 4,
  CoreMaxUniqIds    : 4,
  // Interconnect
  AddrWidth         : 48,
  AxiDataWidth      : 64,
  AxiUserWidth      : 2,  // Convention: bit 0 for core(s), bit 1 for serial link
  AxiMstIdWidth     : 2,
  AxiMaxMstTrans    : 8,
  AxiMaxSlvTrans    : 8,
  AxiUserAmoMsb     : 1,
  AxiUserAmoLsb     : 0,
  RegMaxReadTxns    : 8,
  RegMaxWriteTxns   : 8,
  RegAmoNumCuts     : 1,
  RegAmoPostCut     : 1,
  // External AXI ports (at most 8 ports and rules)
  AxiExtNumMst      : 0,
  AxiExtNumSlv      : AxiNumExtSlv,
  AxiExtNumRules    : AxiNumExtSlv,
  // External AXI region map
  AxiExtRegionIdx  : '{0,0,0,0,0,SafetyIslandIdx,L2Port2Idx,L2Port1Idx},
  AxiExtRegionStart: '{0,0,0,0,0,SafetyIslandBase,L2Port2Base,L2Port1Base},
  AxiExtRegionEnd  : '{0,0,0,0,0,SafetyIslandEnd,L2Port2End,L2Port1End},
  // RTC
  RtcFreq           : 32768,
  // Features
  Bootrom           : 1,
  Uart              : 1,
  I2c               : 1,
  SpiHost           : 1,
  Gpio              : 1,
  Dma               : 1,
  SerialLink        : 1,
  Vga               : 1,
  // Debug
  DbgIdCode         : CheshireIdCode,
  DbgMaxReqs        : 4,
  DbgMaxReadTxns    : 4,
  DbgMaxWriteTxns   : 4,
  DbgAmoNumCuts     : 1,
  DbgAmoPostCut     : 1,
  // LLC: 128 KiB, up to 2 GiB DRAM
  LlcNotBypass      : 1,
  LlcSetAssoc       : 8,
  LlcNumLines       : 256,
  LlcNumBlocks      : 8,
  LlcMaxReadTxns    : 8,
  LlcMaxWriteTxns   : 8,
  LlcAmoNumCuts     : 1,
  LlcAmoPostCut     : 1,
  LlcOutConnect     : 1,
  LlcOutRegionStart : 'h8000_0000,
  LlcOutRegionEnd   : 'h1_0000_0000,
  // VGA: RGB332
  VgaRedWidth       : 3,
  VgaGreenWidth     : 3,
  VgaBlueWidth      : 2,
  VgaHCountWidth    : 24, // TODO: Default is 32; is this needed?
  VgaVCountWidth    : 24, // TODO: See above
  // Serial Link: map other chip's lower 32bit to 'h1_000_0000
  SlinkMaxTxnsPerId : 4,
  SlinkMaxUniqIds   : 4,
  SlinkMaxClkDiv    : 1024,
  SlinkRegionStart  : 'h1_0000_0000,
  SlinkRegionEnd    : 'h2_0000_0000,
  SlinkTxAddrMask   : 'hFFFF_FFFF,
  SlinkTxAddrDomain : 'h0000_0000,
  SlinkUserAmoBit   : 1,  // Upper atomics bit for serial link
  // DMA config
  DmaConfMaxReadTxns  : 4,
  DmaConfMaxWriteTxns : 4,
  DmaConfAmoNumCuts   : 1,
  DmaConfAmoPostCut   : 1,
  // GPIOs
  GpioInputSyncs    : 1,
  // All non-set values should be zero
  default: '0
};

/*****************/
/* L2 Parameters */
/*****************/
localparam int unsigned NumL2Ports = 2;
localparam int unsigned L2MemSize = 2**20;
localparam int unsigned L2NumRules = 4; // 2 rules per each access mode
                                        // (interleaved, non-interleaved)
localparam doub_bt L2Port1NonInterlBase = L2Port1Base + L2MemSize;
localparam doub_bt L2Port2NonInterlBase = L2Port2Base + L2MemSize;

/****************************/
/* Safety Island Parameters */
/****************************/
localparam int unsigned LogDepth = 3;
localparam int unsigned SafetyIslandMemOffset = 'h0020_0000;
localparam int unsigned SafetyIslandPerOffset = 'h0010_0000;

endpackage
