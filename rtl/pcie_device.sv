
module pcie_device (
    input logic         clk,
    input logic         reset,

    input logic         wr_en,
    input logic [11:0]   wr_addr,
    input logic [31:0]  wr_data,
    input logic [3:0] wr_be,

    input logic         rd_en,
    input logic [11:0]   rd_addr,
    output logic [31:0] rd_data
);

    /*
        Internal Signals
    */

    logic [31:0] src_addr;
    logic [31:0] length;

    logic       start_pulse;

    logic busy;
    logic done;

    /*
        Register Block
    */

    pcie_registers registers_inst (
        .clk(clk),
        .reset(reset),

        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .wr_be(wr_be),

        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_data(rd_data),

        .src_addr(src_addr),
        .length(length),

        .start_pulse(start_pulse),

        .busy(busy),
        .done(done)
    );

    /*
        Accelerator Block
    */

    simple_accelerator accelerator_inst (
        .clk(clk),
        .reset(reset),

        .start(start_pulse),

        .src_addr(src_addr),
        .length(length),

        .busy(busy),
        .done(done)
    );

endmodule
