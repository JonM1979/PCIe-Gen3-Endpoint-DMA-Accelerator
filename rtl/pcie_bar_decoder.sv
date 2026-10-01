
module pcie_bar_decoder #(
    parameter logic [63:0] BAR0_BASE = 64'h0000_0000_8000_0000,
    parameter logic [63:0] BAR0_SIZE = 64'h0000_0000_0000_1000, // 4KB

) (
    input logic [63:0] req_addr,

    output logic        bar0_hit,
    output logic [11:0] bar0_offset
);

    always_comb begin

        // checking if the request address falls within the BAR0 range
        bar0_hit = 1'b0;
        bar0_offset = 12'h000;

        if( (req_addr >= BAR0_BASE) && (req_addr < (BAR0_BASE + BAR0_SIZE)) ) begin
            bar0_hit = 1'b1;
            bar0_offset = req_addr - BAR0_BASE;
        end
    end
endmodule
