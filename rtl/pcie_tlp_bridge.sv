
module pcie_tlp_bridge (

    input logic         clk,
    input logic         reset,

    /*
        Parsed PCIe Request
    */
    input logic         req_valid,

    // 00 = Memory Read, 01 = Memory Write
    input logic [1:0]   req_type,

    input logic [63:0]  req_addr,
    input logic [31:0]  req_data,

    input logic [10:0]  req_dw_count, // in DWORDs

    input logic [3:0] req_first_be,
    input logic [3:0] req_last_be,

    input logic [15:0] req_requester_id,
    input logic [7:0]  req_tag,

    /*
        BAR Information
    */
    input logic  bar0_hit,
    input logic [11:0] bar0_offset,


    /*
        Internal Register Bus
    */

    output logic        wr_en,
    output logic [7:0]  wr_addr,
    output logic [31:0] wr_data,
    output logic [3:0]  wr_be,

    output logic        rd_en,
    output logic [7:0]  rd_addr,
    input logic [31:0]  rd_data,

    /*
        Simplified PCIe Completion
    */
    output logic        cpl_valid,
    output logic [2:0] cpl_status, // 00 = Success, 01 = Unsupported Request, 10 = Config Request, 11 = Completer Abort
    output logic [15:0] cpl_requester_id,
    output logic [7:0]  cpl_tag,
    output logic [31:0] cpl_data
);

    localparam logic [1:0] MEM_READ  = 2'b00;
    localparam logic [1:0] MEM_WRITE = 2'b01;

    localparam logic [2:0] CPL_SUCCESS = 3'b000;
    localparam logic [2:0] CPL_UR= 3'b001;

    logic valid_one_dw_request;

    /*
        Request Validation
    */
    always_comb begin
        valid_one_dw_request = bar0_hit && (req_dw_count == 11'd1) && (req_first_be != 4'h0) && (req_last_be != 4'h0);
    end

    /*
        Request -> Register Bus
    */

    always_comb begin
        
        // Default values
        wr_en = 1'b0;
        wr_addr = 12'h00;
        wr_data = 32'h00000000;
        wr_be = 4'h0;

        rd_en = 1'b0;
        rd_addr = 12'h00;

        // if the request is valid and it's a one-DWORD request, we can process it
        if (req_valid && valid_one_dw_request) begin

            // Memory Write
            case (req_type) begin
                MEM_WRITE: begin
                    wr_en = 1'b1;
                    wr_addr = bar0_offset;
                    wr_data = req_data;
                    wr_be = req_first_be;
                end

                MEM_READ: begin
                    if(req_first_be == 4'b1111) begin
                        rd_en =1'b1
                        rd_addr = bar0_offset;
                    end
                end

                default: begin
                    // Unsupported request type, do nothing
                end
            endcase
        end
    end

    /*
        Generate PCIe completion for reads
    */

    always_ff @(posedge clk) begin
        
        if (reset) begin
            cpl_valid <= 1'b0;
            cpl_status <= CPL_SUCCESS;
            cpl_requester_id <= 16'h0000;
            cpl_tag <= 8'h00;
            cpl_data <= 32'h00000000;
        end
        else begin
            // Default: completion only lasts one cycle
            cpl_valid <= 1'b0;

            // Memory reads require a completion
            if(req_valid && (req_type == MEM_READ)) begin
                cpl_valid <= 1'b1;
                cpl_requester_id <= req_requester_id;
                cpl_tag <= req_tag;

                if(valid_one_dw_request && (req_first_be == 4'b1111)) begin
                    cpl_status <= CPL_SUCCESS;
                    cpl_data <= rd_data;
                end
                else begin
                    cpl_status <= CPL_UR; // Unsupported request
                    cpl_data <= 32'h00000000;
                end
            end
        end
    end

endmodule
