
module pcie_tlp_bridge (

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
        Register Interface
    */

    output logic        wr_en,
    output logic [7:0]  wr_addr,
    output logic [31:0] wr_data,

    output logic        rd_en,
    output logic [7:0]  rd_addr,
    input logic [31:0]  rd_data,

    /*
        Simplified PCIe Completion
    */
    output logic        cpl_valid,
    output logic [7:0]  cpl_tag,
    output logic [31:0] cpl_data

);

    /*
        Convert incoming TLPs to register operations
    */

    always_comb begin
        
        // Default values
        wr_en = 1'b0;
        wr_addr = 8'h00;
        wr_data = 32'h00000000;

        rd_en = 1'b0;
        rd_addr = 8'h00;

        if (tlp_valid) begin

            // Memory Write
            if (tlp_is_write) begin
                wr_en = 1'b1;
                wr_addr = tlp_addr[7:0];
                wr_data = tlp_data;
            end
            else begin
                // Read operation
                rd_en = 1'b1;
                rd_addr = tlp_addr[7:0];
            end
        end
    end

    /*
        Generate PCIe completion for reads
    */

    always_ff @(posedge clk) begin
        
        if (reset) begin
            cpl_valid <= 1'b0;
            cpl_tag <= 8'h00;
            cpl_data <= 32'h00000000;
        end
        else begin
            // Default: completion only lasts one cycle
            cpl_valid <= 1'b0;

            // Memory reads require a completion
            if(tlp_valid && !tlp_is_write) begin
                cpl_valid <= 1'b1;
                cpl_tag <= tlp_tag;
                cpl_data <= rd_data;
            end
        end
    end

endmodule
