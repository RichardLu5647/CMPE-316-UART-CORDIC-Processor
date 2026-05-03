`timescale 1ns / 1ps
module top_tb();

    // DUT Signals
    logic clk;
    logic rst;  
    logic rx_in;
    logic tx_out;

    parameter CLK_DIVISION = 867; // 100MHz clock, 115200 baud
    parameter CLOCK_PERIOD = 10;  // 10ns = 100MHz
    parameter BIT_PERIOD = CLK_DIVISION * CLOCK_PERIOD; // 8670ns
    
    initial clk = 0;
    always #5 clk = ~clk; 
    
    // Instantiate DUT 
    top dut4(
    .clk(clk),
    .rst(rst),
    .rx_in(rx_in),
    .tx_out(tx_out)
    );

    // Sends data
    task test_input(input [31:0] input_data);
        automatic logic [15:0] received;  // Stores data transmitted from top module.
        begin
        // Sends the data in 4 parts with most significant first.
        for (int j = 4; j > 0; j--) begin
            // Start bit.
            rx_in = 0;
            #BIT_PERIOD;
            // Sends the AH, AL, DH, and DL.
            for(int i=0; i<8; i++) begin
                rx_in = input_data[(8 * j) - 8 + i];
                #BIT_PERIOD;
            end
            // Stop bit.
            rx_in = 1;
            #BIT_PERIOD;
        end

        // Capture the high and low data transmitted from top module. High data first.
        for (int j = 2; j > 0; j--)begin
            // Wait for the start bit.
            @(negedge tx_out);
            #(BIT_PERIOD / 2); // Half-bit delay
            // Stores received data from top module.
            for(int i=0; i<8; i++) begin
                #BIT_PERIOD;
                received[((8 * j) - 8) + i] = tx_out;
            end
            // Verify stop bit
            #BIT_PERIOD;
        end
        
        $display("Time: %0t | rx_in: 0x%h | tx_out: 0x%h",
                 $time, input_data, received);
        end
    endtask


    initial begin
        // Initialize
        rst = 1;
        rx_in = 1;
        
        // Reset sequence
        rst = 0;
        repeat (5) @(negedge clk);
        rst = 1;
        repeat (5) @(negedge clk);
        rst = 0;
        repeat (5) @(negedge clk);
        #100;
        
        $display("\n===== Starting Top Module Test =====");
        test_input(32'h00000009);  // Outputs "00 00"
        test_input(32'h00000016);  // Outputs "00 03"
        test_input(32'h01000009);  // Outputs "00 04"
        test_input(32'h10000001);  // Outputs "00 03"
        $display("===== Test Completed =====");
        #100 $finish;
    end
endmodule
