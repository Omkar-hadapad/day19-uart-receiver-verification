//==============================================================
// DAY 19 - UART RECEIVER WITH SAFETY MEASURES
// Digital VLSI / Verilog RTL Training
//
// UART FORMAT
// -------------------------------------------------------------
// Data       : 8 bits
// Parity     : None
// Stop       : 1 bit
// Bit Order  : LSB first
// Idle RX    : 1
// Start Bit  : 0
//
// CLKS_PER_BIT = 4
//
// SAFETY FEATURES
// -------------------------------------------------------------
// 1. RX input synchronizer
// 2. Start-bit qualification
// 3. Framing-error detection
// 4. data_valid only for valid frame
// 5. Safe reset state
// 6. Busy indication
// 7. Received data held until next valid frame
//
//==============================================================


//==============================================================
// 1. BASIC GATES
//==============================================================

module rx_and_gate(
    input a,
    input b,
    output y
);
    assign y = a & b;
endmodule


module rx_or_gate(
    input a,
    input b,
    output y
);
    assign y = a | b;
endmodule


module rx_not_gate(
    input a,
    output y
);
    assign y = ~a;
endmodule


module rx_xor_gate(
    input a,
    input b,
    output y
);
    assign y = a ^ b;
endmodule


module rx_nand_gate(
    input a,
    input b,
    output y
);
    assign y = ~(a & b);
endmodule


module rx_nor_gate(
    input a,
    input b,
    output y
);
    assign y = ~(a | b);
endmodule


//==============================================================
// 2. HALF ADDER
//==============================================================

module uart_rx_half_adder(
    input a,
    input b,
    output sum,
    output carry
);

    assign sum   = a ^ b;
    assign carry = a & b;

endmodule


//==============================================================
// 3. FULL ADDER
//==============================================================

module uart_rx_full_adder(
    input a,
    input b,
    input cin,
    output sum,
    output carry
);

    wire s1;
    wire c1;
    wire c2;

    uart_rx_half_adder HA1(
        .a(a),
        .b(b),
        .sum(s1),
        .carry(c1)
    );

    uart_rx_half_adder HA2(
        .a(s1),
        .b(cin),
        .sum(sum),
        .carry(c2)
    );

    rx_or_gate OR1(
        .a(c1),
        .b(c2),
        .y(carry)
    );

endmodule


//==============================================================
// 4. 4-BIT INCREMENTER
//==============================================================

module uart_rx_incrementer_4bit(
    input [3:0] a,
    output [3:0] y
);

    assign y = a + 4'b0001;

endmodule


//==============================================================
// 5. RX INPUT SYNCHRONIZER
//
// RX is asynchronous to clk.
//
// Two flip-flop stages reduce the probability of metastability
// propagating into the UART receiver.
//
//==============================================================

module uart_rx_synchronizer(
    input clk,
    input reset,
    input rx_async,

    output reg rx_sync
);

    reg rx_meta;

    always @(posedge clk)
    begin

        if(reset)
        begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end

        else
        begin
            rx_meta <= rx_async;
            rx_sync <= rx_meta;
        end

    end

endmodule


//==============================================================
// 6. UART RX BAUD COUNTER
//
// CLKS_PER_BIT = 4
//
// Count sequence:
//
// 0 -> 1 -> 2 -> 3 -> 0
//
// Tick occurs at count = 3.
//
//==============================================================

module uart_rx_baud_counter(
    input clk,
    input reset,
    input enable,

    output reg [1:0] count,
    output baud_tick
);

    always @(posedge clk)
    begin

        if(reset)
            count <= 2'b00;

        else if(!enable)
            count <= 2'b00;

        else if(count == 2'b11)
            count <= 2'b00;

        else
            count <= count + 2'b01;

    end

    assign baud_tick =
        enable && (count == 2'b11);

endmodule


//==============================================================
// 7. RX DATA REGISTER
//==============================================================

module uart_rx_data_register(
    input clk,
    input reset,
    input clear,
    input load,

    input rx,
    input [2:0] bit_count,

    output reg [7:0] data
);

    always @(posedge clk)
    begin

        if(reset)
            data <= 8'h00;

        else if(clear)
            data <= 8'h00;

        else if(load)
            data[bit_count] <= rx;

    end

endmodule


//==============================================================
// 8. RX BIT COUNTER
//==============================================================

module uart_rx_bit_counter(
    input clk,
    input reset,
    input enable,
    input clear,

    output reg [2:0] count,
    output last_bit
);

    always @(posedge clk)
    begin

        if(reset)
            count <= 3'd0;

        else if(clear)
            count <= 3'd0;

        else if(enable)
        begin

            if(count != 3'd7)
                count <= count + 3'd1;

        end

    end

    assign last_bit =
        (count == 3'd7);

endmodule


//==============================================================
// 9. UART RX FSM
//
// IDLE -> START -> DATA -> STOP -> IDLE
//
//==============================================================

module uart_rx_fsm(
    input clk,
    input reset,

    input rx,
    input baud_tick,
    input last_bit,

    output reg [1:0] state,
    output reg [1:0] next_state
);

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;


    always @(*)
    begin

        next_state = state;

        case(state)

            IDLE:
            begin

                if(rx == 1'b0)
                    next_state = START;

            end


            START:
            begin

                if(baud_tick)
                    next_state = DATA;

            end


            DATA:
            begin

                if(baud_tick && last_bit)
                    next_state = STOP;

            end


            STOP:
            begin

                if(baud_tick)
                begin

                    if(rx == 1'b1)
                        next_state = IDLE;

                    else
                        next_state = IDLE;

                end

            end


            default:
                next_state = IDLE;

        endcase

    end


    always @(posedge clk)
    begin

        if(reset)
            state <= IDLE;

        else
            state <= next_state;

    end

endmodule


//==============================================================
// 10. RX CONTROL LOGIC
//
// SAFETY:
// -------------------------------------------------------------
// data_valid is asserted only when:
//      state = STOP
//      baud_tick = 1
//      RX = 1
//
// Framing error is asserted when STOP = 0.
//
//==============================================================

module uart_rx_logic(
    input [1:0] state,
    input rx,
    input baud_tick,

    output reg sample_data,
    output reg clear_data,

    output reg data_valid,
    output reg framing_error,

    output reg busy
);

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;


    always @(*)
    begin

        sample_data  = 1'b0;
        clear_data   = 1'b0;

        data_valid   = 1'b0;
        framing_error = 1'b0;

        busy = 1'b0;


        case(state)

            IDLE:
            begin

                busy = 1'b0;

                // New frame detected
                if(rx == 1'b0)
                    clear_data = 1'b1;

            end


            START:
            begin

                busy = 1'b1;

            end


            DATA:
            begin

                busy = 1'b1;

                if(baud_tick)
                    sample_data = 1'b1;

            end


            STOP:
            begin

                busy = 1'b1;

                if(baud_tick)
                begin

                    if(rx == 1'b1)
                    begin

                        // Valid STOP bit
                        data_valid = 1'b1;

                    end

                    else
                    begin

                        // Invalid STOP bit
                        framing_error = 1'b1;

                    end

                end

            end


            default:
            begin

                busy = 1'b0;

            end

        endcase

    end

endmodule


//==============================================================
// 11. STRUCTURAL UART RECEIVER
//
// Safety architecture:
//
// RX
// |
// v
// Synchronizer
// |
// v
// FSM / Baud / Bit Counter
// |
// v
// Data Register
// |
// v
// Safety Validation
// |
// +----> data_valid
// +----> framing_error
//
//==============================================================

module uart_receiver_structural(
    input clk,
    input reset,
    input rx,

    output data_valid,
    output framing_error,
    output busy,

    output [7:0] data_out
);

    //==========================================================
    // Internal signals
    //==========================================================

    wire rx_sync;

    wire [1:0] state;

    wire [1:0] baud_count;
    wire baud_tick;

    wire [2:0] bit_count;
    wire last_bit;

    wire sample_data;
    wire clear_data;

    wire internal_valid;
    wire internal_framing_error;

    wire [7:0] received_data;

    wire enable_baud;


    //==========================================================
    // RX SYNCHRONIZER
    //==========================================================

    uart_rx_synchronizer RX_SYNC(
        .clk(clk),
        .reset(reset),
        .rx_async(rx),

        .rx_sync(rx_sync)
    );


    //==========================================================
    // BAUD ENABLE
    //==========================================================

    assign enable_baud =
        (state != 2'b00);


    //==========================================================
    // BAUD COUNTER
    //==========================================================

    uart_rx_baud_counter BAUD_COUNTER(
        .clk(clk),
        .reset(reset),
        .enable(enable_baud),

        .count(baud_count),
        .baud_tick(baud_tick)
    );


    //==========================================================
    // RX DATA REGISTER
    //==========================================================

    uart_rx_data_register DATA_REGISTER(
        .clk(clk),
        .reset(reset),

        .clear(clear_data),
        .load(sample_data),

        .rx(rx_sync),
        .bit_count(bit_count),

        .data(received_data)
    );


    //==========================================================
    // BIT COUNTER
    //==========================================================

    uart_rx_bit_counter BIT_COUNTER(
        .clk(clk),
        .reset(reset),

        .enable(sample_data),
        .clear(clear_data),

        .count(bit_count),
        .last_bit(last_bit)
    );


    //==========================================================
    // FSM
    //==========================================================

    uart_rx_fsm FSM(
        .clk(clk),
        .reset(reset),

        .rx(rx_sync),
        .baud_tick(baud_tick),
        .last_bit(last_bit),

        .state(state),
        .next_state()
    );


    //==========================================================
    // RX CONTROL / SAFETY
    //==========================================================

    uart_rx_logic RX_LOGIC(
        .state(state),
        .rx(rx_sync),
        .baud_tick(baud_tick),

        .sample_data(sample_data),
        .clear_data(clear_data),

        .data_valid(internal_valid),
        .framing_error(internal_framing_error),

        .busy(busy)
    );


    //==========================================================
    // SAFE OUTPUT DATA
    //
    // Data is available only after a valid frame.
    //
    //==========================================================

    reg [7:0] safe_data;

    always @(posedge clk)
    begin

        if(reset)
        begin
            safe_data <= 8'h00;
        end

        else if(internal_valid)
        begin
            safe_data <= received_data;
        end

    end


    //==========================================================
    // OUTPUTS
    //==========================================================

    assign data_out       = safe_data;

    assign data_valid     = internal_valid;

    assign framing_error  = internal_framing_error;


endmodule


//==============================================================
// 12. RTL UART RECEIVER WITH SAFETY
//==============================================================

module uart_receiver_rtl(
    input clk,
    input reset,
    input rx,

    output reg data_valid,
    output reg framing_error,
    output reg busy,

    output reg [7:0] data_out
);

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;


    reg [1:0] state;

    reg [1:0] baud_count;

    reg [2:0] bit_count;

    reg [7:0] received_data;

    reg rx_meta;
    reg rx_sync;


    wire baud_tick;


    //==========================================================
    // RX SYNCHRONIZER
    //==========================================================

    always @(posedge clk)
    begin

        if(reset)
        begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end

        else
        begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end

    end


    //==========================================================
    // BAUD TICK
    //==========================================================

    assign baud_tick =
        (state != IDLE) &&
        (baud_count == 2'b11);


    //==========================================================
    // MAIN RTL
    //==========================================================

    always @(posedge clk)
    begin

        if(reset)
        begin

            state          <= IDLE;

            baud_count     <= 2'b00;
            bit_count      <= 3'b000;

            received_data  <= 8'h00;
            data_out       <= 8'h00;

            data_valid     <= 1'b0;
            framing_error  <= 1'b0;

            busy           <= 1'b0;

        end

        else
        begin

            // One-cycle status pulses
            data_valid    <= 1'b0;
            framing_error <= 1'b0;


            case(state)

                //------------------------------------------------
                // IDLE
                //------------------------------------------------

                IDLE:
                begin

                    busy       <= 1'b0;
                    baud_count <= 2'b00;

                    if(rx_sync == 1'b0)
                    begin

                        state         <= START;

                        busy          <= 1'b1;

                        bit_count     <= 3'b000;
                        received_data <= 8'h00;

                    end

                end


                //------------------------------------------------
                // START
                //------------------------------------------------

                START:
                begin

                    busy <= 1'b1;

                    if(baud_tick)
                    begin

                        state      <= DATA;
                        baud_count <= 2'b00;

                    end

                    else
                    begin

                        baud_count <= baud_count + 2'b01;

                    end

                end


                //------------------------------------------------
                // DATA
                //------------------------------------------------

                DATA:
                begin

                    busy <= 1'b1;

                    if(baud_tick)
                    begin

                        received_data[bit_count] <= rx_sync;

                        baud_count <= 2'b00;

                        if(bit_count == 3'd7)
                        begin

                            state <= STOP;

                        end

                        else
                        begin

                            bit_count <= bit_count + 3'd1;

                        end

                    end

                    else
                    begin

                        baud_count <= baud_count + 2'b01;

                    end

                end


                //------------------------------------------------
                // STOP
                //------------------------------------------------

                STOP:
                begin

                    busy <= 1'b1;

                    if(baud_tick)
                    begin

                        baud_count <= 2'b00;

                        if(rx_sync == 1'b1)
                        begin

                            // Valid STOP
                            data_out      <= received_data;

                            data_valid    <= 1'b1;

                            framing_error <= 1'b0;

                            busy  <= 1'b0;
                            state <= IDLE;

                        end

                        else
                        begin

                            // Invalid STOP
                            framing_error <= 1'b1;

                            // Do not update data_out
                            busy  <= 1'b0;
                            state <= IDLE;

                        end

                    end

                    else
                    begin

                        baud_count <= baud_count + 2'b01;

                    end

                end


                //------------------------------------------------
                // DEFAULT
                //------------------------------------------------

                default:
                begin

                    state      <= IDLE;
                    baud_count <= 2'b00;
                    bit_count  <= 3'b000;

                    busy <= 1'b0;

                end

            endcase

        end

    end

endmodule


//==============================================================
// 13. TOP MODULE
//
// Recommended synthesis top.
//
//==============================================================

module uart_receiver_top(
    input clk,
    input reset,
    input rx,

    output data_valid,
    output framing_error,
    output busy,

    output [7:0] data_out
);

    uart_receiver_structural UART_RX(
        .clk(clk),
        .reset(reset),
        .rx(rx),

        .data_valid(data_valid),
        .framing_error(framing_error),
        .busy(busy),

        .data_out(data_out)
    );

endmodule