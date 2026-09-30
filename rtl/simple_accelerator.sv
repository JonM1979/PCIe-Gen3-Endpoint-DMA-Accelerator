
module simple_accelerator (
    input logic         clk,
    input logic         reset,

    input logic         start,

    input logic [31:0] src_addr,
    input logic [31:0] length, 

    output logic        busy,
    output logic        done
);

    /*
        State Definition
    */

    typedef enum logic [1:0] {
        IDLE,
        WORK,
        DONE_STATE

    } state_t;

    state_t state;

    /*
        Simple cycle counter
    */

    logic [3:0] work_counter;

    /*
        State Machine
    */
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            work_counter <= 4'h0;
        end
        else begin
            case (state)
                // Wait for START command
                IDLE: begin

                    work_counter <= 4'h0;

                    if (start) begin
                        state <= WORK;
                    end
                end

                // Pretend we're processing data
                WORK: begin

                    if (work_counter == 4'd7) begin
                        work_counter <= 4'd0;
                        state <= DONE_STATE;
                    end 
                    else begin
                        work_counter <= work_counter + 1'b1;
                    end
                end

                // Signal completion for one cycle
                DONE_STATE: begin

                    state <= IDLE;

                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    /*
        Output Logic
    */

    always_comb begin

        busy = 1'b0;
        done = 1'b0;

        case (state)

            IDLE: begin
                busy = 1'b0;
                done = 1'b0;
            end

            WORK: begin
                busy = 1'b1;
                done = 1'b0;
            end

            DONE_STATE: begin
                busy = 1'b0;
                done = 1'b1;
            end

            default: begin
                busy = 1'b0;
                done = 1'b0;
            end
        endcase
    end

endmodule
