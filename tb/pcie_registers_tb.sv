`timescale 1ns/1ps

module pcie_registers_tb;

    /*
        Testbench signals 
    */

    logic         clk;
    logic         reset;

    logic         wr_en;
    logic [7:0]   wr_addr;
    logic [31:0]  wr_data;

    logic         rd_en;
    logic [7:0]   rd_addr;

    logic [31:0]  rd_data;

    /*
        DUT Instance
    */

    pcie_device dut (
        .clk(clk),
        .reset(reset),

        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),

        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

    /*
        Clock Generation
    */
    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk; // 100MHz clock
    end

    /*
        Register Write Task
    */   

    task automatic write_reg(
        input logic [7:0] address,
        input logic [31:0] data   
    );
        begin

            // Drive signals away from positive edge
            @(negedge clk);

            wr_en = 1'b1;
            wr_addr = address;
            wr_data = data;

            // Samples these values on the next posedge
            @(negedge clk);

            // Remove write request
            wr_en = 1'b0;
            wr_addr = 8'h00;
            wr_data = 32'h00000000;
        end
    endtask

    /*
        Register Read and Check Task
    */    

    task automatic check_reg(
        input logic [7:0] address,
        input logic [31:0] expected
    );

        begin
            @(negedge clk);

            rd_en = 1'b1;
            rd_addr = address;

            // Allow combinational read logic to settle
            #1;
            
            if(rd_data != expected) begin

                $error(
                    "FAIL: address = 0x%02h expected=0x%08h actual=0x%08h",
                    address,
                    expected,
                    rd_data
                );
            end
            else begin
                $display(
                    "PASS: address=0x%02h data=0x%08h",
                    address,
                    rd_data
                );
            end

            @(negedge clk);

            rd_en = 1'b0;
            rd_addr = 8'h00;
        end
    endtask

    /*
        Main Test Sequence
    */
    initial begin

        reset = 1'b1;

        wr_en = 1'b0;
        wr_addr = 8'h00;
        wr_data = 32'h00000000;

        rd_en = 1'b0;
        rd_addr = 8'h00;

        $display("================================");
        $display("Register PCIe Block Testbench");
        $display("================================");
        $display("");

        // Reset DUT 

        repeat (2)
            @(posedge clk);

        reset = 1'b0;

        @(posedge clk);

        $display("Reset complete.");
        $display("");

        // TEST 1: Confirm all registers reset to zero

        $display("TEST 1: Reset Values");

        check_reg(
            8'h00,
            32'h00000000
        );

        check_reg(
            8'h04,
            32'h00000000
        );

        check_reg(
            8'h08,
            32'h00000000
        );

        check_reg(
            8'h0C,
            32'h00000000
        );

        $display("");

        /*
            TEST 2: Write/Read SRC_ADDR 
        */

        $display("TEST 2: SRC_ADDR Register");

        write_reg(
            8'h08,
            32'h1000200
        );

        check_reg(
            8'h08,
            32'h1000200
        );

        $display("");

        /*
            TEST 3: Write/Read LENGTH
        */

        $display("TEST 3: LENGTH Register");

        write_reg(
            8'h0C,
            32'h00001000
        );

        check_reg(
            8'h0C,
            32'h00001000
        );

        $display("");

        /*
            TEST 4: Write/Read CONTROL
        */

        $display("TEST 4: CONTROL Register");

        write_reg(
            8'h04,
            32'h00000001
        );

        check_reg(
            8'h04,
            32'h00000001
        );

        $display("");

        /*
            TEST 5: STATUS should remain read-only
        */

        $display("TEST 5: STATUS Read-Only Test");

        write_reg(
            8'h00,
            32'hFFFFFFFF
        );

        check_reg(
            8'h00,
            32'h00000000
        );

        $display("");

        /*
            TEST 6: Undefined Address
        */

        $display("TEST 6: Undefined Address Test");

        check_reg(
            8'h10,
            32'hDEADBEEF
        );

        /*
            TEST 7: Accelerator START/BUSY/DONE Test
        */

        $display("TEST 7: Accelerator START/BUSY/DONE Test");

        // configure source address
        write_reg(
            8'h08,
            32'h10002000
        );

        // Configure length
        write_reg(
            8'h0C,
            32'h00001000
        );

        // Start the accelerator
        write_reg(
            8'h00,
            32'h00000001
        );

        // Allow FSM to enter WORK state
        @(posedge clk);

        // STATUS should now show BUSY
        check_reg(
            8'h04,
            32'h00000001
        );

        // Wait for the accelerator to finish
        repeat (8) 
            @(posedge clk);

        // STATUS should now show DONE
        check_reg(
            8'h04,
            32'h00000002
        );

        $display("");

        $display("================================");
        $display("All tests complete.");
        $display("================================");
        $display("");

        $finish;
    end
endmodule

