`timescale 1ns / 1ps

module top (
    input clk,
    input rx_in, 
    output tx_out,
    input rst
);
    // UART Interface
    logic [7:0] rx_data;
    logic rx_empty, tx_empty;
    logic uld_rx_data, ld_tx_data;
    logic [7:0] tx_data;
    logic rx_enable, tx_enable;
    
    //CORDIC Interface
    logic m_axis_dout_tvalid;
    logic [15:0] m_axis_dout_tdata;
    logic [15:0] s_axis_cartesian_tdata;
    logic s_axis_cartesian_tvalid;
    
    // RAM Interface
    logic wea;
    logic [15:0] dataIn;
    logic [15:0] dataOut;
    logic [15:0] mem_address;
    
    //FSM States
    typedef enum logic [3:0] {
        IDLE, 
        RECEIVE_AH, 
        RECEIVE_AL, 
        RECEIVE_DH, 
        RECEIVE_DL,  
        PROCESS_CORDIC,
        READ_RAM, 
        WRITE_RAM,
        SEND_HIGH,
        BUFFER,
        SEND_LOW
    } state_t;
    
    state_t current_state;
    
    // Temp vectors to store data.
    logic [15:0] old_data, new_data;  
    
    // FSM State Transitions
    always @(posedge clk, posedge rst) begin 
        // Resets registers and data.
        if (rst) begin 
            mem_address <= 16'b0;
            new_data <= 16'b0;
            old_data <= 16'b0;
            uld_rx_data <= 1'b0;
            ld_tx_data <= 1'b0;
            tx_data <= 8'b0;
            wea <= 1'b0;
            dataIn <= 16'b0;
            s_axis_cartesian_tdata <= 16'b0;
            s_axis_cartesian_tvalid <= 1'b0;
            current_state <= IDLE;
        end else begin 
            // Case statements.
            case (current_state) 
                // Idle sets flags to 0.
                IDLE: begin 
                    uld_rx_data <= 1'b0;
                    ld_tx_data <= 1'b0;
                    wea <= 1'b0;
                    s_axis_cartesian_tvalid <= 1'b0;
                    // Only moves on if rx_in has recieved data.
                    if (~rx_empty) begin 
                        current_state <= RECEIVE_AH;
                    end 
                    else begin
                        current_state <= IDLE;
                    end
                end
                // Receives the high address.
                RECEIVE_AH: begin 
                    uld_rx_data <= 1'b1;  // Allows data to go to rx_data
                    mem_address[15:8] <= rx_data;  // Stores in high bits of mem_address.
                    // Moves onto next state only if data was loaded.
                    if (~rx_empty) begin
                        current_state <= RECEIVE_AL;
                    end
                    else begin
                        current_state <= RECEIVE_AH;
                    end
                end
                // Recieves the low address.
                RECEIVE_AL: begin 
                    uld_rx_data <= 1'b1;
                    mem_address[7:0] <= rx_data;  // Stores in low bits of mem_address.
                    if (~rx_empty) begin
                        current_state <= RECEIVE_DH;
                    end
                    else begin
                        current_state <= RECEIVE_AL;
                    end
                end
                // Recieves the high bits of data.
                RECEIVE_DH: begin 
                    uld_rx_data <= 1'b1;
                    new_data[15:8] <= rx_data;  // Stores in high bits of data_store.
                    if (~rx_empty) begin
                        current_state <= RECEIVE_DL;
                    end
                    else begin
                        current_state <= RECEIVE_DH;
                    end
                end
                // Recieves the low bits of data.
                RECEIVE_DL: begin 
                    uld_rx_data <= 1'b1;
                    new_data[7:0] <= rx_data;  // Stores in low bits of data_store.
                    // Moves on when all data is unloaded.
                    if (rx_empty) begin
                        current_state <= PROCESS_CORDIC;
                    end
                    else begin
                        current_state <= RECEIVE_DL;
                    end
                end
            
                // Square roots the data.
                PROCESS_CORDIC: begin 
                    s_axis_cartesian_tvalid <= 1'b1;  // Makes it valid so value can be square rooted.
                    s_axis_cartesian_tdata <= new_data;  // Data to be square rooted.
                    current_state <= WRITE_RAM;
                end
                // Writes new data into RAM. 
                WRITE_RAM: begin 
                    wea <= 1'b1; // Enables writing
                    s_axis_cartesian_tvalid <= 1'b0;  // Turns the square root off.
                    // If the data outputed from CORDIC is valid.
                    if (m_axis_dout_tvalid) begin
                        dataIn <= m_axis_dout_tdata;  // Stores the data into RAM.
                        current_state <= READ_RAM;
                    end
                    else begin
                        current_state <= WRITE_RAM;
                    end   
                end
                // Collects data from RAM to send out.
                READ_RAM: begin 
                    wea <= 1'b0;  // Disables writing so data can be read.
                    old_data <= dataOut; // Stores data from RAM previously to old_data.
                    current_state <= SEND_HIGH;
                end
                // Sends the high bits of old data.
                SEND_HIGH: begin 
                    tx_data <= old_data[15:8];  // Sends high bits first.
                    // Makes sure transmitter is ready to send new value.
                    if (tx_empty) begin 
                        ld_tx_data <= 1'b1;  // Readies the data to be sent.
                        current_state <= BUFFER;
                    end
                    else begin
                        current_state <= SEND_HIGH;
                    end 
                end
                // Buffer to reload the ld_tx_data.
                BUFFER: begin
                    // Makes sure no new data is loaded until transmitter is empty again.
                    if (~tx_empty) begin 
                        ld_tx_data <= 1'b0;  // Stopes data to be sent.
                        current_state <= SEND_LOW;
                    end
                    else begin
                        current_state <= BUFFER;
                    end 
                end
                // Sends the lower bits
                SEND_LOW: begin 
                    tx_data <= old_data[7:0];
                    if (tx_empty) begin 
                        ld_tx_data <= 1'b1;
                        current_state <= IDLE;
                    end
                    else begin
                        current_state <= SEND_LOW;
                    end 
                end
                             
            endcase
        end
    end

// Uart module
uart uart_mod (
  .reset(rst),    // input wire rst
  .ld_tx_data(ld_tx_data), // initiate load 8 bits and send if ready to send
  .tx_data(tx_data), // internal data 8 bit to send
  .tx_enable(1'b1), // typically just set to 1
  .tx_out(tx_out), // external communication line 1 bit 
  .tx_empty(tx_empty), // indicated finished send and ready to send new value
  .clk(clk),
  .uld_rx_data(~rx_empty), // move new internal data to show up on rx_data
  .rx_data(rx_data), // internal data 8 bit receive
  .rx_enable(1'b1), // usually just set to 1
  .rx_in(rx_in), // external communication line 1 bit 
  .rx_empty(rx_empty)         // recieved serial data has been unloaded to rx_data output register, leaving room for new input serial byte
);

// Where the data is square rooted.
cordic_0 square_rooted (
  .aclk(clk),                                        // input wire aclk
  .s_axis_cartesian_tvalid(s_axis_cartesian_tvalid),  // input wire s_axis_cartesian_tvalid
  .s_axis_cartesian_tdata(s_axis_cartesian_tdata),    // input wire [15 : 0] s_axis_cartesian_tdata
  .m_axis_dout_tvalid(m_axis_dout_tvalid),            // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(m_axis_dout_tdata)              // output wire [15 : 0] m_axis_dout_tdata
);
// The RAM
blk_mem_gen_0 ram (
  .clka(clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wea),      // input wire [0 : 0] wea
  .addra(mem_address[11:0]),  // input wire [11 : 0] addra
  .dina(dataIn),    // input wire [15 : 0] dina
  .douta(dataOut)  // output wire [15 : 0] douta
);
endmodule
