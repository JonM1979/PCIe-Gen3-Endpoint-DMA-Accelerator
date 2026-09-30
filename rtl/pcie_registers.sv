// registers over which data is transferred between the PCIe core and the user logic

module pcie_registers (
    input logic         clk,
    input logic         reset,

    // Write Interface
    input logic         wr_en,
    input logic [7:0]   wr_addr,
    input logic [31:0]  wr_data,

    // Read Interface
    input logic         rd_en,
    input logic [7:0]   rd_addr,
    output logic [31:0] rd_data,

    // Configuration outputs to hardware
    output logic [31:0] src_addr,
    output logic [31:0] length,

    // Command Output
    output logic        start_pulse,

    // Hardware status inputs
    input logic         busy,
    input logic         done
);

/*
Register Map and Definitions:
    0x00: Control Register
    0x04: Status Register
    0x08: Data Register
    0x0C: Length Register
*/


    /*
        Address Map
    */
    localparam logic [7:0] CONTROL_ADDR = 8'h00;
    localparam logic [7:0] STATUS_ADDR = 8'h04;
    localparam logic [7:0] SRC_ADDR_ADDR = 8'h08;
    localparam logic [7:0] LENGTH_ADDR = 8'h0C;

    // Write Logic
    always_ff @(posedge clk) begin
        if (reset) begin
            src_addr <= 32'h00000000;
            length <= 32'h00000000;
            start_pulse <= 1'b0;
        end 
        else begin

            // START is a one-cycle pulse
            start_pulse <= 1'b0;

            if (wr_en) begin

                case (wr_addr)

                    CONTROL_ADDR: begin
                        if (wr_data[0])
                            start_pulse <= 1'b1; // Set start pulse if bit 0 is set
                    end

                    SRC_ADDR_ADDR: begin
                        src_addr <= wr_data;
                    end

                    LENGTH_ADDR: begin
                        length <= wr_data;
                    end

                    default: begin
                        // Invalid address, ignore write or handle error
                    end
                endcase
                
            endcase
        end
    end

    // Read Logic
    always_comb begin
        rd_data = 32'h00000000; // Default value

        if(rd_en) begin

            case (rd_addr)

                CONTROL_ADDR: begin
                    rd_data = 32'h00000000; // Control register is write-only, return 0
                end

                STATUS_ADDR: begin
                    // STATUS[0] = BUSY
                    //STATUS[1] = DONE
                    rd_data = {
                        30'b0, 
                        done, 
                        busy
                    };
                end

                SRC_ADDR_ADDR: begin
                    rd_data = src_addr;
                end

                LENGTH_ADDR: begin
                    rd_data = length;
                end

                default:
                    // Invalid address, return 0 or handle error
                    rd_data = 32'hDEADBEEF; // Example error code
            endcase
        end
    end

endmodule
