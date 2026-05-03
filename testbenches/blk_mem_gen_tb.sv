`timescale 1ns / 1ps
module blk_mem_gen_tb();
    logic clk;
    logic enable;
    
    logic wea;
    logic [11:0] mem_address;
    logic [15:0] din;
    logic [15:0] dout;
    
    initial clk = 0;
    always #5 clk = ~clk;

    blk_mem_gen_0 dut2 (
      .clka(clk),    
      .ena(enable),      
      .wea(wea),      
      .addra(mem_address),  
      .dina(din),    
      .douta(dout)  
    );

    // Task that uses the stimulus on the module.
    task test_input(input logic [15:0] value, input logic [11:0] address); 
        begin 
            @(posedge clk);
            wea <= 1;
            din <= value;
            mem_address <= address;
            @(posedge clk);
            wea <= 0;
            @(posedge clk);

            $display("Time: %0t | Address: 0x%11b | Input Data: 0x%04X (%0d) | Output Data: 0x%04X (%0d)",
                      $time, address, value, value, dout, dout);
        end
    endtask
    // Start Test
    initial begin 
        
        // Initialize
        enable = 0;
        repeat (2) @(posedge clk);
        enable = 1;  // Should always be enabled.
        
        $display("===== Starting RAM IN/OUT Test =====");
        // Stimulus
        test_input(16'h0001, 11'b00000000000);  // dout = xx xx because no previous data was there.
        test_input(16'h0009, 11'b00000000000);  // dout = 00 01
        test_input(16'h0016, 11'b00000000000);  // dout = 00 09
        test_input(16'h0012, 11'b00000000001);  // dout = 00 16
        
        $display("===== Test Completed =====");
        
        #20;
        $finish;
    end
    
    

endmodule
