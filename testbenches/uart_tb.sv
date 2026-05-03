`timescale 1ns / 1ps
module uart_tb();

    // DUT Signals
    logic clk;
    logic rst;  

    logic ld_tx_data;
    logic [7:0] tx_data;
    logic tx_enable;
    logic tx_out;
    logic tx_empty;

    logic uld_rx_data;
    logic [7:0] rx_data;
    logic rx_enable;
    logic rx_in;
    logic rx_empty;

    parameter CLK_DIVISION = 867; // 100MHz clock, 115200 baud
    parameter CLOCK_PERIOD = 10;  // 10ns = 100MHz
    parameter BIT_PERIOD = CLK_DIVISION * CLOCK_PERIOD;
    
    initial clk = 0;
    always #5 clk = ~clk; 
    
    // Instantiate DUT 
    uart dut (
        .reset(rst),       
        .ld_tx_data(ld_tx_data),
        .tx_data(tx_data),
        .tx_enable(tx_enable),
        .tx_out(tx_out),
        .tx_empty(tx_empty),
        .clk(clk),
        .uld_rx_data(uld_rx_data),
        .rx_data(rx_data),
        .rx_enable(rx_enable),
        .rx_in(rx_in),
        .rx_empty(rx_empty)
    );

    // Sends data via uart.
    task test_input(input bit [7:0] value);
        automatic logic [7:0] received;
        begin
            // Send byte.
            rx_in = 1; // Idle
            #BIT_PERIOD;
            
            // Start bit
            rx_in = 0;
            #BIT_PERIOD;
            
            // Data bits
            for(int i=0; i<8; i++) begin
                rx_in = value[i];
                #BIT_PERIOD;
            end
            
            // Stop bit
            rx_in = 1;
            #BIT_PERIOD;
            
            // Wait for data received
            wait(rx_empty == 0);
            @(posedge clk);
            uld_rx_data = 1;
            @(posedge clk);
            uld_rx_data = 0;
            
            // Send received data
            tx_data = rx_data;
            ld_tx_data = 1;
            @(posedge clk);
            ld_tx_data = 0;
            
            // Receive TX data
            receive_uart_task(value);
        end
    endtask

    // Prints out transmitted data.
    task receive_uart_task(input [7:0] expected);
        automatic logic [7:0] received;
        begin
            // Wait for start bit
            @(negedge tx_out);
            #(BIT_PERIOD/2);
            
            // Capture data bits
            for(int i=0; i<8; i++) begin
                #BIT_PERIOD;
                received[i] = tx_out;
            end
            
            // Verify stop bit
            #BIT_PERIOD;
            
            // Display results
            $display("Time: %0t | rx_in: 0x%h | tx_out: 0x%h",
                     $time, expected, received);
        end
    endtask

    initial begin
        // Initialize
        rst = 1;
        ld_tx_data = 0;
        tx_data = 0;
        tx_enable = 1;
        rx_enable = 1;
        rx_in = 1;
        uld_rx_data = 0;
        
        rst = 0;
        repeat (5) @(negedge clk);
        rst = 1;
        repeat (5) @(negedge clk);
        rst = 0;
        repeat (5) @(negedge clk);
        #100;
        
        $display("\n===== Starting UART Test =====");
        test_input(8'hA5);
        test_input(8'h3C);
        test_input(8'h7E);
        $display("===== Test Completed =====");
        #100 $finish;
    end
endmodule
