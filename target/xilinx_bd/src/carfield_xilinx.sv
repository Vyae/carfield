// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Nicole Narr <narrn@student.ethz.ch>
// Christopher Reinwardt <creinwar@student.ethz.ch>
// Cyril Koenig <cykoenig@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "cheshire/typedef.svh"

module carfield_xilinx
  import carfield_pkg::*;
  import cheshire_pkg::*;
  import safety_island_pkg::*;
(
  input  logic         cpu_reset,

  input  logic         clk_10,
  input  logic         clk_20,
  input  logic         clk_50,
  input  logic         clk_100,

  input  logic         testmode_i,
  input  logic [1:0]   boot_mode_i,
  input  logic [1:0]   boot_mode_safety_i,

  input  logic         jtag_tck_i,
  input  logic         jtag_tms_i,
  input  logic         jtag_tdi_i,
  output logic         jtag_tdo_o,
  input  logic         jtag_trst_ni,
  output logic         jtag_vdd_o,
  output logic         jtag_gnd_o,

  output logic         uart_tx_o,
  input  logic         uart_rx_i,

  // Dram axi

  output wire dram_axi_m_aclk,
  output wire dram_axi_m_aresetn,

  output wire [6:0] dram_axi_m_axi_awid,
  output wire [47:0] dram_axi_m_axi_awaddr,
  output wire [7:0] dram_axi_m_axi_awlen,
  output wire [2:0] dram_axi_m_axi_awsize,
  output wire [1:0] dram_axi_m_axi_awburst,
  output wire dram_axi_m_axi_awlock,
  output wire [3:0] dram_axi_m_axi_awcache,
  output wire [2:0] dram_axi_m_axi_awprot,
  output wire [3:0] dram_axi_m_axi_awqos,
  output wire dram_axi_m_axi_awvalid,
  input  wire dram_axi_m_axi_awready,

  output wire [63:0] dram_axi_m_axi_wdata,
  output wire [7:0] dram_axi_m_axi_wstrb,
  output wire dram_axi_m_axi_wlast,
  output wire dram_axi_m_axi_wvalid,
  input  wire dram_axi_m_axi_wready,

  output wire dram_axi_m_axi_bready,
  input  wire [6:0] dram_axi_m_axi_bid,
  input  wire [1:0] dram_axi_m_axi_bresp,
  input  wire dram_axi_m_axi_bvalid,

  output wire [6:0]dram_axi_m_axi_arid,
  output wire [47:0] dram_axi_m_axi_araddr,
  output wire [7:0] dram_axi_m_axi_arlen,
  output wire [2:0] dram_axi_m_axi_arsize,
  output wire [1:0] dram_axi_m_axi_arburst,
  output wire dram_axi_m_axi_arlock,
  output wire [3:0] dram_axi_m_axi_arcache,
  output wire [2:0] dram_axi_m_axi_arprot,
  output wire [3:0] dram_axi_m_axi_arqos,
  output wire dram_axi_m_axi_arvalid,
  input  wire dram_axi_m_axi_arready,

  output wire dram_axi_m_axi_rready,
  input  wire [6:0] dram_axi_m_axi_rid,
  input  wire [63:0] dram_axi_m_axi_rdata,
  input  wire [1:0] dram_axi_m_axi_rresp,
  input  wire dram_axi_m_axi_rlast,
  input  wire dram_axi_m_axi_rvalid,

  // Periph axi

  output wire periph_axi_m_aclk,
  output wire periph_axi_m_aresetn,

  output wire [1:0] periph_axi_m_axi_awid,
  output wire [47:0] periph_axi_m_axi_awaddr,
  output wire [7:0] periph_axi_m_axi_awlen,
  output wire [2:0] periph_axi_m_axi_awsize,
  output wire [1:0] periph_axi_m_axi_awburst,
  output wire periph_axi_m_axi_awlock,
  output wire [3:0] periph_axi_m_axi_awcache,
  output wire [2:0] periph_axi_m_axi_awprot,
  output wire [3:0] periph_axi_m_axi_awqos,
  output wire periph_axi_m_axi_awvalid,
  input  wire periph_axi_m_axi_awready,

  output wire [63:0] periph_axi_m_axi_wdata,
  output wire [7:0] periph_axi_m_axi_wstrb,
  output wire periph_axi_m_axi_wlast,
  output wire periph_axi_m_axi_wvalid,
  input  wire periph_axi_m_axi_wready,

  output wire periph_axi_m_axi_bready,
  input  wire [1:0] periph_axi_m_axi_bid,
  input  wire [1:0] periph_axi_m_axi_bresp,
  input  wire periph_axi_m_axi_bvalid,

  output wire [1:0]periph_axi_m_axi_arid,
  output wire [47:0] periph_axi_m_axi_araddr,
  output wire [7:0] periph_axi_m_axi_arlen,
  output wire [2:0] periph_axi_m_axi_arsize,
  output wire [1:0] periph_axi_m_axi_arburst,
  output wire periph_axi_m_axi_arlock,
  output wire [3:0] periph_axi_m_axi_arcache,
  output wire [2:0] periph_axi_m_axi_arprot,
  output wire [3:0] periph_axi_m_axi_arqos,
  output wire periph_axi_m_axi_arvalid,
  input  wire periph_axi_m_axi_arready,

  output wire periph_axi_m_axi_rready,
  input  wire [1:0] periph_axi_m_axi_rid,
  input  wire [63:0] periph_axi_m_axi_rdata,
  input  wire [1:0] periph_axi_m_axi_rresp,
  input  wire periph_axi_m_axi_rlast,
  input  wire periph_axi_m_axi_rvalid

);

  ///////////////////////////
  // Clk reset definitions //
  ///////////////////////////

  logic cpu_resetn;
  assign cpu_resetn = ~cpu_reset;
  logic sys_rst;

  wire soc_clk, host_clk, alt_clk, periph_clk;
  (* dont_touch = "yes" *)  wire rst_n;

  ///////////////////
  // GPIOs         // 
  ///////////////////

  // Give VDD and GND to JTAG
  assign jtag_vdd_o  = '1;
  assign jtag_gnd_o  = '0;

  //////////////////
  // Clock Wizard //
  //////////////////

  localparam rtc_clk_divider = 4;
  assign soc_clk = clk_50;
  assign alt_clk = clk_20;
  assign host_clk = soc_clk;
  assign periph_clk = soc_clk;

  /////////////////////
  // Reset Generator //
  /////////////////////

  rstgen i_rstgen_main (
    .clk_i        ( soc_clk                  ),
    .rst_ni       ( ~sys_rst                 ),
    .test_mode_i  ( testmode_i              ),
    .rst_no       ( rst_n                    ),
    .init_no      (                          ) // keep open
  );

  ///////////////////
  // VIOs          //
  ///////////////////

  logic [1:0] boot_mode, boot_mode_safety;

  assign sys_rst = cpu_reset;
  assign boot_mode = boot_mode_i;
  assign boot_mode_safety = boot_mode_safety_i;

  /////////////////////////
  // "RTC" Clock Divider //
  /////////////////////////

  (* dont_touch = "yes" *) logic rtc_clk_d, rtc_clk_q;
  logic [4:0] counter_d, counter_q;

  // Divide clk_10 => 1 MHz RTC Clock
  always_comb begin
    counter_d = counter_q + 1;
    rtc_clk_d = rtc_clk_q;

    if(counter_q == rtc_clk_divider) begin
      counter_d = 5'b0;
      rtc_clk_d = ~rtc_clk_q;
    end
  end

  always_ff @(posedge clk_10, negedge rst_n) begin
    if(~rst_n) begin
      counter_q <= 5'b0;
      rtc_clk_q <= 0;
    end else begin
      counter_q <= counter_d;
      rtc_clk_q <= rtc_clk_d;
    end
  end

  //////////////////
  // Carfield Cfg //
  //////////////////

`ifndef GEN_PULP_CLUSTER
`define GEN_PULP_CLUSTER 0
`endif
`ifndef GEN_SAFETY_ISLAND
`define GEN_SAFETY_ISLAND 0
`endif
`ifndef GEN_SPATZ_CLUSTER
`define GEN_SPATZ_CLUSTER 0
`endif
`ifndef GEN_OPEN_TITAN
`define GEN_OPEN_TITAN 0
`endif

`define HypNumChips 1
`define HypNumPhys 1

  localparam cheshire_cfg_t Cfg = carfield_pkg::CarfieldCfgDefault;
  `CHESHIRE_TYPEDEF_ALL(carfield_, Cfg)

  localparam islands_cfg_t IslandsCfg = '{
    EnPulpCluster   : `GEN_PULP_CLUSTER,
    EnSafetyIsland  : `GEN_SAFETY_ISLAND,
    EnSpatzCluster  : `GEN_SPATZ_CLUSTER,
    EnOpenTitan     : `GEN_OPEN_TITAN,
    EnCan           : 0,
    EnEthernet      : 0,
    default         : '1
  };

  ///////////////////
  // LLC interface //
  ///////////////////

  localparam axi_in_t   AxiIn   = gen_axi_in(Cfg);
  localparam int unsigned LlcIdWidth = Cfg.AxiMstIdWidth+$clog2(AxiIn.num_in)+Cfg.LlcNotBypass;
  localparam int unsigned LlcArWidth = (2**LogDepth)*axi_pkg::ar_width(Cfg.AddrWidth,LlcIdWidth,Cfg.AxiUserWidth);
  localparam int unsigned LlcAwWidth = (2**LogDepth)*axi_pkg::aw_width(Cfg.AddrWidth,LlcIdWidth,Cfg.AxiUserWidth);
  localparam int unsigned LlcBWidth  = (2**LogDepth)*axi_pkg::b_width(LlcIdWidth,Cfg.AxiUserWidth);
  localparam int unsigned LlcRWidth  = (2**LogDepth)*axi_pkg::r_width(Cfg.AxiDataWidth,LlcIdWidth,Cfg.AxiUserWidth);
  localparam int unsigned LlcWWidth  = (2**LogDepth)*axi_pkg::w_width(Cfg.AxiDataWidth,Cfg.AxiUserWidth);
  // LLC interface
  logic [LlcArWidth-1:0] llc_ar_data;
  logic [    LogDepth:0] llc_ar_wptr;
  logic [    LogDepth:0] llc_ar_rptr;
  logic [LlcAwWidth-1:0] llc_aw_data;
  logic [    LogDepth:0] llc_aw_wptr;
  logic [    LogDepth:0] llc_aw_rptr;
  logic [ LlcBWidth-1:0] llc_b_data;
  logic [    LogDepth:0] llc_b_wptr;
  logic [    LogDepth:0] llc_b_rptr;
  logic [ LlcRWidth-1:0] llc_r_data;
  logic [    LogDepth:0] llc_r_wptr;
  logic [    LogDepth:0] llc_r_rptr;
  logic [ LlcWWidth-1:0] llc_w_data;
  logic [    LogDepth:0] llc_w_wptr;
  logic [    LogDepth:0] llc_w_rptr;
  // Axi interface
  carfield_axi_llc_req_t llc_req;
  carfield_axi_llc_rsp_t llc_rsp;

  axi_cdc_dst      #(
  .LogDepth     ( LogDepth                   ),
  .axi_req_t    ( carfield_axi_llc_req_t     ),
  .axi_resp_t   ( carfield_axi_llc_rsp_t     ),
  .w_chan_t     ( carfield_axi_llc_w_chan_t  ),
  .b_chan_t     ( carfield_axi_llc_b_chan_t  ),
  .ar_chan_t    ( carfield_axi_llc_ar_chan_t ),
  .r_chan_t     ( carfield_axi_llc_r_chan_t  ),
  .aw_chan_t    ( carfield_axi_llc_aw_chan_t )
  ) i_hyper_cdc_dst (
  .async_data_slave_aw_data_i ( llc_aw_data ),
  .async_data_slave_aw_wptr_i ( llc_aw_wptr ),
  .async_data_slave_aw_rptr_o ( llc_aw_rptr ),
  .async_data_slave_w_data_i  ( llc_w_data  ),
  .async_data_slave_w_wptr_i  ( llc_w_wptr  ),
  .async_data_slave_w_rptr_o  ( llc_w_rptr  ),
  .async_data_slave_b_data_o  ( llc_b_data  ),
  .async_data_slave_b_wptr_o  ( llc_b_wptr  ),
  .async_data_slave_b_rptr_i  ( llc_b_rptr  ),
  .async_data_slave_ar_data_i ( llc_ar_data ),
  .async_data_slave_ar_wptr_i ( llc_ar_wptr ),
  .async_data_slave_ar_rptr_o ( llc_ar_rptr ),
  .async_data_slave_r_data_o  ( llc_r_data  ),
  .async_data_slave_r_wptr_o  ( llc_r_wptr  ),
  .async_data_slave_r_rptr_i  ( llc_r_rptr  ),
  // synchronous master port
  .dst_clk_i                  ( soc_clk     ),
  .dst_rst_ni                 ( rst_n       ),
  .dst_req_o                  ( llc_req   ),
  .dst_resp_i                 ( llc_rsp   )
);

  assign dram_axi_m_aclk             = soc_clk;
  assign dram_axi_m_aresetn          = rst_n;

  assign dram_axi_m_axi_awid         = llc_req.aw.id;
  assign dram_axi_m_axi_awaddr       = llc_req.aw.addr;
  assign dram_axi_m_axi_awlen        = llc_req.aw.len;
  assign dram_axi_m_axi_awsize       = llc_req.aw.size;
  assign dram_axi_m_axi_awburst      = llc_req.aw.burst;
  assign dram_axi_m_axi_awlock       = llc_req.aw.lock;
  assign dram_axi_m_axi_awcache      = llc_req.aw.cache;
  assign dram_axi_m_axi_awprot       = llc_req.aw.prot;
  assign dram_axi_m_axi_awqos        = llc_req.aw.qos;
  assign dram_axi_m_axi_awvalid      = llc_req.aw_valid;
  assign llc_rsp.aw_ready           = dram_axi_m_axi_awready;

  assign dram_axi_m_axi_wdata        = llc_req.w.data;
  assign dram_axi_m_axi_wstrb        = llc_req.w.strb;
  assign dram_axi_m_axi_wlast        = llc_req.w.last;
  assign dram_axi_m_axi_wvalid       = llc_req.w_valid;
  assign llc_rsp.w_ready             = dram_axi_m_axi_wready;

  assign dram_axi_m_axi_bready       = llc_req.b_ready;
  assign llc_rsp.b.id               = dram_axi_m_axi_bid;
  assign llc_rsp.b.resp             = dram_axi_m_axi_bresp;
  assign llc_rsp.b_valid            = dram_axi_m_axi_bvalid;

  assign dram_axi_m_axi_arid         = llc_req.ar.id;
  assign dram_axi_m_axi_araddr       = llc_req.ar.addr;
  assign dram_axi_m_axi_arlen        = llc_req.ar.len;
  assign dram_axi_m_axi_arsize       = llc_req.ar.size;
  assign dram_axi_m_axi_arburst      = llc_req.ar.burst;
  assign dram_axi_m_axi_arlock       = llc_req.ar.lock;
  assign dram_axi_m_axi_arcache      = llc_req.ar.cache;
  assign dram_axi_m_axi_arprot       = llc_req.ar.prot;
  assign dram_axi_m_axi_arqos        = llc_req.ar.qos;
  assign dram_axi_m_axi_arvalid      = llc_req.ar_valid;
  assign llc_rsp.ar_ready           = dram_axi_m_axi_arready;

  assign dram_axi_m_axi_rready       = llc_req.r_ready;
  assign llc_rsp.r.id               = dram_axi_m_axi_rid;
  assign llc_rsp.r.data             = dram_axi_m_axi_rdata;
  assign llc_rsp.r.resp             = dram_axi_m_axi_rresp;
  assign llc_rsp.r.last             = dram_axi_m_axi_rlast;
  assign llc_rsp.r_valid            = dram_axi_m_axi_rvalid;

  /////////////////////////////////
  // Serial Link to block design //
  /////////////////////////////////

  // Serial link interface
  logic [SlinkNumChan-1:0]                     slink_clk_soc_periph;
  logic [SlinkNumChan-1:0]                     slink_clk_periph_soc;
  logic [SlinkNumChan-1:0][SlinkNumLanes-1:0]  slink_soc_periph;
  logic [SlinkNumChan-1:0][SlinkNumLanes-1:0]  slink_periph_soc;

  carfield_axi_mst_req_t periph_req;
  carfield_axi_mst_rsp_t periph_rsp;

  serial_link #(
    .axi_req_t    ( carfield_axi_mst_req_t ),
    .axi_rsp_t    ( carfield_axi_mst_rsp_t ),
    .cfg_req_t    ( carfield_reg_req_t ),
    .cfg_rsp_t    ( carfield_reg_rsp_t ),
    .aw_chan_t    ( carfield_axi_mst_aw_chan_t ),
    .ar_chan_t    ( carfield_axi_mst_ar_chan_t ),
    .r_chan_t     ( carfield_axi_mst_r_chan_t  ),
    .w_chan_t     ( carfield_axi_mst_w_chan_t  ),
    .b_chan_t     ( carfield_axi_mst_b_chan_t  ),
    .hw2reg_t     ( serial_link_single_channel_reg_pkg::serial_link_single_channel_hw2reg_t ),
    .reg2hw_t     ( serial_link_single_channel_reg_pkg::serial_link_single_channel_reg2hw_t ),
    .NumChannels  ( SlinkNumChan   ),
    .NumLanes     ( SlinkNumLanes  ),
    .MaxClkDiv    ( SlinkMaxClkDiv )
  ) i_serial_link (
    .clk_i          ( host_clk  ),
    .rst_ni         ( rst_n     ),
    .clk_sl_i       ( host_clk  ),
    .rst_sl_ni      ( rst_n     ),
    .clk_reg_i      ( host_clk  ),
    .rst_reg_ni     ( rst_n     ),
    .testmode_i     ( testmode_i ),
    .axi_in_req_i   ( '0 ),
    .axi_in_rsp_o   (    ),
    .axi_out_req_o  ( periph_req ),
    .axi_out_rsp_i  ( periph_rsp ),
    .cfg_req_i      ( '0 ),
    .cfg_rsp_o      (    ),
    .ddr_rcv_clk_i  ( slink_clk_soc_periph ),
    .ddr_rcv_clk_o  ( slink_clk_periph_soc ),
    .ddr_i          ( slink_soc_periph ),
    .ddr_o          ( slink_periph_soc ),
    .isolated_i     ( '0 ),
    .isolate_o      ( ),
    .clk_ena_o      ( ),
    .reset_no       ( )
  );

  assign periph_axi_m_aclk             = soc_clk;
  assign periph_axi_m_aresetn          = rst_n;

  assign periph_axi_m_axi_awid         = periph_req.aw.id;
  assign periph_axi_m_axi_awaddr       = periph_req.aw.addr;
  assign periph_axi_m_axi_awlen        = periph_req.aw.len;
  assign periph_axi_m_axi_awsize       = periph_req.aw.size;
  assign periph_axi_m_axi_awburst      = periph_req.aw.burst;
  assign periph_axi_m_axi_awlock       = periph_req.aw.lock;
  assign periph_axi_m_axi_awcache      = periph_req.aw.cache;
  assign periph_axi_m_axi_awprot       = periph_req.aw.prot;
  assign periph_axi_m_axi_awqos        = periph_req.aw.qos;
  assign periph_axi_m_axi_awvalid      = periph_req.aw_valid;
  assign periph_rsp.aw_ready           = periph_axi_m_axi_awready;

  assign periph_axi_m_axi_wdata        = periph_req.w.data;
  assign periph_axi_m_axi_wstrb        = periph_req.w.strb;
  assign periph_axi_m_axi_wlast        = periph_req.w.last;
  assign periph_axi_m_axi_wvalid       = periph_req.w_valid;
  assign periph_rsp.w_ready            = periph_axi_m_axi_wready;

  assign periph_axi_m_axi_bready       = periph_req.b_ready;
  assign periph_rsp.b.id               = periph_axi_m_axi_bid;
  assign periph_rsp.b.resp             = periph_axi_m_axi_bresp;
  assign periph_rsp.b_valid            = periph_axi_m_axi_bvalid;

  assign periph_axi_m_axi_arid         = periph_req.ar.id;
  assign periph_axi_m_axi_araddr       = periph_req.ar.addr;
  assign periph_axi_m_axi_arlen        = periph_req.ar.len;
  assign periph_axi_m_axi_arsize       = periph_req.ar.size;
  assign periph_axi_m_axi_arburst      = periph_req.ar.burst;
  assign periph_axi_m_axi_arlock       = periph_req.ar.lock;
  assign periph_axi_m_axi_arcache      = periph_req.ar.cache;
  assign periph_axi_m_axi_arprot       = periph_req.ar.prot;
  assign periph_axi_m_axi_arqos        = periph_req.ar.qos;
  assign periph_axi_m_axi_arvalid      = periph_req.ar_valid;
  assign periph_rsp.ar_ready           = periph_axi_m_axi_arready;

  assign periph_axi_m_axi_rready       = periph_req.r_ready;
  assign periph_rsp.r.id               = periph_axi_m_axi_rid;
  assign periph_rsp.r.data             = periph_axi_m_axi_rdata;
  assign periph_rsp.r.resp             = periph_axi_m_axi_rresp;
  assign periph_rsp.r.last             = periph_axi_m_axi_rlast;
  assign periph_rsp.r_valid            = periph_axi_m_axi_rvalid;

  //////////////////
  // Carfield SoC //
  //////////////////

  logic jtag_host_to_safety, jtag_safety_to_ot;

  carfield #(
      .Cfg       (carfield_pkg::CarfieldCfgDefault),
      .IslandsCfg(IslandsCfg),
      .reg_req_t(carfield_reg_req_t),
      .reg_rsp_t(carfield_reg_rsp_t),
      .LlcIdWidth   ( LlcIdWidth ),
      .LlcArWidth   ( LlcArWidth ),
      .LlcAwWidth   ( LlcAwWidth ),
      .LlcBWidth    ( LlcBWidth  ),
      .LlcRWidth    ( LlcRWidth  ),
      .LlcWWidth    ( LlcWWidth  ),
      .HypNumPhys   (`HypNumPhys),
      .HypNumChips  (`HypNumChips)
  ) i_carfield (
      .host_clk_i    (host_clk),
      .periph_clk_i  (periph_clk),
      .alt_clk_i     (alt_clk),
      .rt_clk_i      (rtc_clk_q),
      .pwr_on_rst_ni (rst_n),
      .test_mode_i   (testmode_i),
      // Boot mode selection
      .boot_mode_i   (boot_mode),
      // Cheshire JTAG Interface
      .jtag_tck_i                (jtag_tck_i),
      .jtag_trst_ni              (jtag_trst_ni),
      .jtag_tms_i                (jtag_tms_i),
      .jtag_tdi_i                (jtag_tdi_i),
      .jtag_tdo_o                (jtag_host_to_safety),
      .jtag_tdo_oe_o             (),
      // Secure Subsystem JTAG Interface
      .jtag_ot_tck_i             (jtag_tck_i),
      .jtag_ot_trst_ni           (jtag_trst_ni),
      .jtag_ot_tms_i             (jtag_tms_i),
      .jtag_ot_tdi_i             (jtag_safety_to_ot),
      .jtag_ot_tdo_o             (jtag_tdo_o), // Take in account when they are unactivated
      .jtag_ot_tdo_oe_o          (),
      // Safety Island JTAG Interface
      .jtag_safety_island_tck_i  (jtag_tck_i),
      .jtag_safety_island_trst_ni(jtag_trst_ni),
      .jtag_safety_island_tms_i  (jtag_tms_i),
      .jtag_safety_island_tdi_i  (jtag_host_to_safety),
      .jtag_safety_island_tdo_o  (jtag_safety_to_ot),
      .bootmode_safe_isln_i      (boot_mode_safety),
      // UART Interface
      .uart_tx_o,
      .uart_rx_i,
      // OT UART Interface
      .uart_ot_tx_o              (),
      .uart_ot_rx_i              (),
      // Controle Flow UART Modem
      //.uart_rts_no               (),
      //.uart_dtr_no               (),
      //.uart_cts_ni               (),
      //.uart_dsr_ni               (),
      //.uart_dcd_ni               (),
      //.uart_rin_ni               (),
      // I2C Interface
      .i2c_sda_o                 (),
      .i2c_sda_i                 (),
      .i2c_sda_en_o              (),
      .i2c_scl_o                 (),
      .i2c_scl_i                 (),
      .i2c_scl_en_o              (),
      // SPI Host Interface
      .spih_sck_o                (),
      .spih_sck_en_o             (),
      .spih_csb_o                (),
      .spih_csb_en_o             (),
      .spih_sd_o                 (),
      .spih_sd_en_o              (),
      .spih_sd_i                 (),
      // GPIO interface
      .gpio_i                    (),
      .gpio_o                    (),
      .gpio_en_o                 (),
      // LLC Interface
      .llc_ar_data,
      .llc_ar_wptr,
      .llc_ar_rptr,
      .llc_aw_data,
      .llc_aw_wptr,
      .llc_aw_rptr,
      .llc_b_data,
      .llc_b_wptr,
      .llc_b_rptr,
      .llc_r_data,
      .llc_r_wptr,
      .llc_r_rptr,
      .llc_w_data,
      .llc_w_wptr,
      .llc_w_rptr,
      // Serial link interface
      .slink_rcv_clk_i(slink_clk_periph_soc),
      .slink_rcv_clk_o(slink_clk_soc_periph),
      .slink_i(slink_periph_soc),
      .slink_o(slink_soc_periph)
  );

endmodule
