# FPGA-UART-CORDIC-System

## Overview
This project implements a hardware data processing system in SystemVerilog that communicates over UART, processes data using a CORDIC module, stores results in RAM, and transmits results back.

The design is controlled by a finite state machine (FSM) that manages data flow between communication, computation, and memory.

## System Architecture
The system performs the following operations:
1. Receives data over UART (byte-by-byte)
2. Constructs 16-bit input data and memory address
3. Processes the data using a CORDIC module (square root computation)
4. Writes processed data to RAM
5. Reads stored data from RAM
6. Sends results back over UART

## Modules

### Top Module
- Implements FSM control logic
- Coordinates UART, CORDIC, and RAM
- Handles data flow and control signals

### UART Module
- Handles serial communication (RX/TX)
- Supports configurable baud rate via clock division
- Implements both receiver and transmitter logic :contentReference[oaicite:0]{index=0}

### CORDIC Module
- Performs square root computation on input data
- Uses streaming interface signals (`tvalid`, `tdata`)

### RAM Module
- Stores processed data
- Supports read and write operations via address input

## FSM States
The system is controlled by a finite state machine with states including:
- IDLE
- RECEIVE_AH / RECEIVE_AL (address input)
- RECEIVE_DH / RECEIVE_DL (data input)
- PROCESS_CORDIC
- WRITE_RAM
- READ_RAM
- SEND_HIGH / SEND_LOW

## Features
- UART-based data communication
- FSM-controlled data pipeline
- Hardware-based square root computation using CORDIC
- RAM storage and retrieval
- Modular design with reusable components

## Testbenches
Testbenches are included to verify functionality of individual modules and system behavior:

- `uart_tb.sv` → UART communication testing
- `cordic_tb.sv` → CORDIC computation validation
- `blk_mem_gen_tb.sv` → RAM testing
- `top_tb.sv` → Full system integration testing

These testbenches validate correct data transmission, computation, and memory operations.
