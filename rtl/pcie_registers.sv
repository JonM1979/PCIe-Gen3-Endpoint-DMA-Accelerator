// registers over which data is transferred between the PCIe core and the user logic

module pcie_registers (
    input logic         clk,
    input logic         reset,

    input logic         wr_en,
    input logic [7:0]   wr_addr,
    input logic [31:0]  wr_data,

    inout logic         rd_en,
    input logic [7:0]   rd_addr,

    output logic [31:0] rd_data,
);

/*
Register Map and Definitions:
    0x00: Control Register
    0x04: Status Register
    0x08: Data Register
    0x0C: Length Register
*/

logic [31:0] control_reg;
logic [31:0] status_reg;
logic [31:0] src_addr_reg;
logic [31:0] length_reg;

localparam logic [7:0] CONTROL_ADDR = 8'h00;
localparam logic [7:0] STATUS_ADDR = 8'h04;
localparam logic [7:0] SRC_ADDR_ADDR = 8'h08;
localparam logic [7:0] LENGTH_ADDR = 8'h0C;

// Write Logic
always_ff @(posedge clk) begin
    if (reset) begin
        control_reg <= 32'b0;
        status_reg <= 32'h0;
        src_addr_reg <= 32'b0;
        length_reg <= 32'b0;
    end 
    else if (wr_en) begin
        case (wr_addr)
            CONTROL_ADDR:
                control_reg <= wr_data;

            SRC_ADDR_ADDR:
                src_addr_reg <= wr_data;

            LENGTH_ADDR:
                length_reg <= wr_data;
            
            default: begin
                // Invalid address, do nothing or handle error
            end
        endcase
    end
end

// Read Logic
always_comb begin
    rd_data = 32'h0;

    if(rd_en) begin
        case (rd_addr)
            CONTROL_ADDR:
                rd_data = control_reg;

            STATUS_ADDR:
                rd_data = status_reg;

            SRC_ADDR_ADDR:
                rd_data = src_addr_reg;

            LENGTH_ADDR:
                rd_data = length_reg;

            default:
                // Invalid address, return 0 or handle error
                rd_data = 32'hDEADBEEF; // Example error code
        endcase
    end
end

endmodule
