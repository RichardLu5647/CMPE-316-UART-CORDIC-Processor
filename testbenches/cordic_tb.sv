`timescale 1ns / 1ps

module cordic_tb();
    logic clk;
    logic rst = 0;

    logic input_valid;
    logic [15:0] in;
    logic output_valid;
    logic [15:0] out;
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    cordic_0 dut1(
    .aclk(clk), 
    .s_axis_cartesian_tvalid(input_valid), 
    .s_axis_cartesian_tdata(in), 
    .m_axis_dout_tvalid(output_valid), 
    .m_axis_dout_tdata(out)
    );
    
    
    // Task that uses the stimulus on the module.
    task test_input(input logic [15:0] value); 
        begin 
            @(posedge clk);
            in <= value;  // Data stored
            input_valid <= 1;  // Validates input
            
            @(posedge clk);
            input_valid <= 0;  // Make sure no new input is used.
            
            wait (output_valid == 1);  // Waits till a valid output is reached.
            @(posedge clk);
            
            $display("Time: %0t | Input: 0x%04X (%0d) | Output: 0x%04X (%0d)",
                      $time, value, value, out, out);
        end
    endtask
    
    // Start Test
    initial begin 
        $display("Time\t\tInput\t\tOutput");
        $display("----------------------------------");
        
        // Initialize
        input_valid = 0;
        in = 0;
        
    rst = 0;
    repeat (5) @(negedge clk);
    rst = 1;
    repeat (5) @(negedge clk);
    rst = 0;
    repeat (5) @(negedge clk);
    #100;
        
        $display("===== Starting CORDIC Square Root Test =====");
        // Stimulus
        test_input(16'h0001); // √1
        test_input(16'h0004); // √4
        test_input(16'h0009); // √9
        test_input(16'h0010); // √16
        test_input(16'h0040); // √64
        test_input(16'h0100); // √256
        
        $display("===== Test Completed =====");
        
        #20;
        $finish;
    end
    
endmodule
