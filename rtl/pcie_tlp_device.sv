
module pcie_tlp_device (
    input logic         clk,
    input logic         reset,

    // Simplified TLP interface
    input logic         tlp_valid,

    // 0 = Memory Read, 1 = Memory Write
    input logic         tlp_is_write,

    input logic [31:0] tlp_addr,
    input logic [31:0] tlp_data,

    // used to match read requests with completions
    input logic [7:0] tlp_tag,

    /*
        Simplified PCIe Completion
    */
    output logic        cpl_valid,
    output logic [7:0]  cpl_tag,
    output logic [31:0] cpl_data
);

    /*
        Internal Register-Bus signals
    */

    logic        wr_en;
    logic [7:0]  wr_addr;
    logic [31:0] wr_data;

    logic        rd_en;
    logic [7:0]  rd_addr;
    logic [31:0]  rd_data;

    /*
        PCIe TLP Bridge
    */
    pcie_tlp_bridge tlp_bridge_inst (
        .clk(clk),
        .reset(reset),

        .tlp_valid(tlp_valid),
        .tlp_is_write(tlp_is_write),
        .tlp_addr(tlp_addr),
        .tlp_data(tlp_data),
        .tlp_tag(tlp_tag),

        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),

        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_data(rd_data),

        .cpl_valid(cpl_valid),
        .cpl_tag(cpl_tag),
        .cpl_data(cpl_data)
    );

    /*
       Existing PCIe Controlled Device
    */
    pcie_device device_inst (
        .clk(clk),
        .reset(reset),

        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),

        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

    