//==============================================================
// DAY 19 - UART RECEIVER TESTBENCH
// Digital VLSI / Verilog RTL Training
//
// DUT:
//      uart_receiver_structural
//      uart_receiver_rtl
//      uart_receiver_top
//
// TESTBENCH FEATURES
// -------------------------------------------------------------
// 1. Basic gate verification
// 2. Half Adder verification
// 3. Full Adder verification
// 4. 4-bit Incrementer verification
// 5. RX Synchronizer verification
// 6. Baud Counter verification
// 7. Data Register verification
// 8. Bit Counter verification
// 9. RX Logic verification
// 10. FSM verification
// 11. Complete UART frame verification
// 12. Multiple data pattern verification
// 13. Back-to-back frame verification
// 14. Framing-error verification
// 15. Structural vs RTL comparison
// 16. TOP module verification
// 17. Reset / idle safety verification
//
// UART FORMAT
// -------------------------------------------------------------
// 8-bit data
// No parity
// 1 start bit
// 1 stop bit
// LSB first
// RX idle = 1
// CLKS_PER_BIT = 4
//
// SAFETY FEATURES
// -------------------------------------------------------------
// 2-flop RX synchronizer
// Valid STOP bit
// Invalid STOP bit detection
// data_valid
// framing_error
// busy
// Safe data retention
//
//==============================================================

`timescale 1ns/1ps


module day19_tb;


//==============================================================
// 1. CLOCK AND RESET
//==============================================================

reg clk;
reg reset;
reg rx;


//==============================================================
// 2. DUT OUTPUTS
//==============================================================

//--------------------------------------------------------------
// Structural DUT
//--------------------------------------------------------------

wire        struct_valid;
wire        struct_error;
wire        struct_busy;
wire [7:0]  struct_data;


//--------------------------------------------------------------
// RTL DUT
//--------------------------------------------------------------

wire        rtl_valid;
wire        rtl_error;
wire        rtl_busy;
wire [7:0]  rtl_data;


//--------------------------------------------------------------
// TOP DUT
//--------------------------------------------------------------

wire        top_valid;
wire        top_error;
wire        top_busy;
wire [7:0]  top_data;


//==============================================================
// 3. TEST VARIABLES
//==============================================================

integer pass_count;
integer fail_count;
integer i;

reg [7:0] test_data;

// Used to remember a framing-error pulse
reg framing_error_seen;


//==============================================================
// 4. UNIT TEST SIGNALS
//==============================================================

//--------------------------------------------------------------
// Basic gates
//--------------------------------------------------------------

reg gate_a;
reg gate_b;

wire gate_and_y;
wire gate_or_y;
wire gate_not_y;
wire gate_xor_y;
wire gate_nand_y;
wire gate_nor_y;


//--------------------------------------------------------------
// Half Adder
//--------------------------------------------------------------

reg ha_a;
reg ha_b;

wire ha_sum;
wire ha_carry;


//--------------------------------------------------------------
// Full Adder
//--------------------------------------------------------------

reg fa_a;
reg fa_b;
reg fa_cin;

wire fa_sum;
wire fa_carry;


//--------------------------------------------------------------
// 4-bit Incrementer
//--------------------------------------------------------------

reg [3:0] inc_a;

wire [3:0] inc_y;


//--------------------------------------------------------------
// RX Synchronizer
//--------------------------------------------------------------

reg sync_rx;

wire sync_rx_out;


//--------------------------------------------------------------
// Baud Counter
//--------------------------------------------------------------

reg baud_enable;

wire [1:0] baud_count;
wire       baud_tick;


//--------------------------------------------------------------
// Data Register
//--------------------------------------------------------------

reg data_clear;
reg data_load;

reg [2:0] data_bit_count;

wire [7:0] data_reg_out;


//--------------------------------------------------------------
// Bit Counter
//--------------------------------------------------------------

reg bit_enable;
reg bit_clear;

wire [2:0] bit_count;
wire       bit_last;


//--------------------------------------------------------------
// RX Logic
//--------------------------------------------------------------

reg [1:0] logic_state;
reg       logic_rx;
reg       logic_baud_tick;

wire logic_sample_data;
wire logic_clear_data;
wire logic_valid;
wire logic_error;
wire logic_busy;


//--------------------------------------------------------------
// FSM
//--------------------------------------------------------------

reg fsm_rx;
reg fsm_baud_tick;
reg fsm_last_bit;

wire [1:0] fsm_state;
wire [1:0] fsm_next_state;


//==============================================================
// 5. BASIC GATE INSTANCES
//==============================================================

rx_and_gate AND_GATE (
    .a(gate_a),
    .b(gate_b),
    .y(gate_and_y)
);

rx_or_gate OR_GATE (
    .a(gate_a),
    .b(gate_b),
    .y(gate_or_y)
);

rx_not_gate NOT_GATE (
    .a(gate_a),
    .y(gate_not_y)
);

rx_xor_gate XOR_GATE (
    .a(gate_a),
    .b(gate_b),
    .y(gate_xor_y)
);

rx_nand_gate NAND_GATE (
    .a(gate_a),
    .b(gate_b),
    .y(gate_nand_y)
);

rx_nor_gate NOR_GATE (
    .a(gate_a),
    .b(gate_b),
    .y(gate_nor_y)
);


//==============================================================
// 6. HALF ADDER
//==============================================================

uart_rx_half_adder HA (
    .a(ha_a),
    .b(ha_b),
    .sum(ha_sum),
    .carry(ha_carry)
);


//==============================================================
// 7. FULL ADDER
//==============================================================

uart_rx_full_adder FA (
    .a(fa_a),
    .b(fa_b),
    .cin(fa_cin),
    .sum(fa_sum),
    .carry(fa_carry)
);


//==============================================================
// 8. 4-BIT INCREMENTER
//==============================================================

uart_rx_incrementer_4bit INCREMENTER (
    .a(inc_a),
    .y(inc_y)
);


//==============================================================
// 9. RX SYNCHRONIZER
//==============================================================

uart_rx_synchronizer SYNCHRONIZER (
    .clk(clk),
    .reset(reset),
    .rx_async(sync_rx),
    .rx_sync(sync_rx_out)
);


//==============================================================
// 10. BAUD COUNTER
//==============================================================

uart_rx_baud_counter BAUD_COUNTER (
    .clk(clk),
    .reset(reset),
    .enable(baud_enable),
    .count(baud_count),
    .baud_tick(baud_tick)
);


//==============================================================
// 11. DATA REGISTER
//==============================================================

uart_rx_data_register DATA_REGISTER (
    .clk(clk),
    .reset(reset),
    .clear(data_clear),
    .load(data_load),
    .rx(rx),
    .bit_count(data_bit_count),
    .data(data_reg_out)
);


//==============================================================
// 12. BIT COUNTER
//==============================================================

uart_rx_bit_counter BIT_COUNTER (
    .clk(clk),
    .reset(reset),
    .enable(bit_enable),
    .clear(bit_clear),
    .count(bit_count),
    .last_bit(bit_last)
);


//==============================================================
// 13. RX LOGIC
//==============================================================

uart_rx_logic RX_LOGIC (
    .state(logic_state),
    .rx(logic_rx),
    .baud_tick(logic_baud_tick),

    .sample_data(logic_sample_data),
    .clear_data(logic_clear_data),

    .data_valid(logic_valid),
    .framing_error(logic_error),

    .busy(logic_busy)
);


//==============================================================
// 14. FSM
//==============================================================

uart_rx_fsm FSM (
    .clk(clk),
    .reset(reset),

    .rx(fsm_rx),
    .baud_tick(fsm_baud_tick),
    .last_bit(fsm_last_bit),

    .state(fsm_state),
    .next_state(fsm_next_state)
);


//==============================================================
// 15. STRUCTURAL UART RECEIVER
//==============================================================

uart_receiver_structural STRUCTURAL_DUT (
    .clk(clk),
    .reset(reset),
    .rx(rx),

    .data_valid(struct_valid),
    .framing_error(struct_error),
    .busy(struct_busy),

    .data_out(struct_data)
);


//==============================================================
// 16. RTL UART RECEIVER
//==============================================================

uart_receiver_rtl RTL_DUT (
    .clk(clk),
    .reset(reset),
    .rx(rx),

    .data_valid(rtl_valid),
    .framing_error(rtl_error),
    .busy(rtl_busy),

    .data_out(rtl_data)
);


//==============================================================
// 17. TOP MODULE
//==============================================================

uart_receiver_top TOP_DUT (
    .clk(clk),
    .reset(reset),
    .rx(rx),

    .data_valid(top_valid),
    .framing_error(top_error),
    .busy(top_busy),

    .data_out(top_data)
);


//==============================================================
// 18. CLOCK GENERATION
//==============================================================

initial
begin
    clk = 1'b0;

    forever
        #5 clk = ~clk;
end


//==============================================================
// 19. CHECK TASK - 1 BIT
//==============================================================

task check_bit;

    input actual;
    input expected;
    input [255:0] name;

    begin

        if(actual === expected)
        begin

            $display(
                "PASS | %s | Expected=%b Actual=%b",
                name,
                expected,
                actual
            );

            pass_count = pass_count + 1;

        end

        else
        begin

            $display(
                "FAIL | %s | Expected=%b Actual=%b",
                name,
                expected,
                actual
            );

            fail_count = fail_count + 1;

        end

    end

endtask


//==============================================================
// 20. CHECK TASK - 4 BIT
//==============================================================

task check_4bit;

    input [3:0] actual;
    input [3:0] expected;
    input [255:0] name;

    begin

        if(actual === expected)
        begin

            $display(
                "PASS | %s | Expected=%h Actual=%h",
                name,
                expected,
                actual
            );

            pass_count = pass_count + 1;

        end

        else
        begin

            $display(
                "FAIL | %s | Expected=%h Actual=%h",
                name,
                expected,
                actual
            );

            fail_count = fail_count + 1;

        end

    end

endtask


//==============================================================
// 21. CHECK TASK - 8 BIT
//==============================================================

task check_8bit;

    input [7:0] actual;
    input [7:0] expected;
    input [255:0] name;

    begin

        if(actual === expected)
        begin

            $display(
                "PASS | %s | Expected=%h Actual=%h",
                name,
                expected,
                actual
            );

            pass_count = pass_count + 1;

        end

        else
        begin

            $display(
                "FAIL | %s | Expected=%h Actual=%h",
                name,
                expected,
                actual
            );

            fail_count = fail_count + 1;

        end

    end

endtask


//==============================================================
// 22. RESET TASK
//==============================================================

task reset_all;

    begin

        reset = 1'b1;
        rx    = 1'b1;

        sync_rx = 1'b1;

        baud_enable = 1'b0;

        data_clear     = 1'b0;
        data_load      = 1'b0;
        data_bit_count = 3'd0;

        bit_enable = 1'b0;
        bit_clear  = 1'b0;

        logic_state     = 2'b00;
        logic_rx        = 1'b1;
        logic_baud_tick = 1'b0;

        fsm_rx        = 1'b1;
        fsm_baud_tick = 1'b0;
        fsm_last_bit  = 1'b0;

        framing_error_seen = 1'b0;

        repeat(3)
        begin

            @(posedge clk);
            #1;

        end

        reset = 1'b0;

        @(posedge clk);
        #1;

    end

endtask


//==============================================================
// 23. UART FRAME TASK
//
// UART FRAME:
//
// IDLE  = 1
// START = 0
// DATA  = 8 bits, LSB first
// STOP  = 1
//
// Synchronizer latency = 2 clocks
// START held = 6 clocks
// DATA bit = 4 clocks
// STOP = 4 clocks
//
//==============================================================

task send_uart_frame;

    input [7:0] frame_data;

    integer k;

    begin

        //------------------------------------------------------
        // IDLE
        //------------------------------------------------------

        rx = 1'b1;

        repeat(2)
        begin

            @(posedge clk);
            #1;

        end


        //------------------------------------------------------
        // START
        //------------------------------------------------------

        rx = 1'b0;

        repeat(6)
        begin

            @(posedge clk);
            #1;

        end


        //------------------------------------------------------
        // DATA
        //------------------------------------------------------

        for(k = 0; k < 8; k = k + 1)
        begin

            rx = frame_data[k];

            repeat(4)
            begin

                @(posedge clk);
                #1;

            end

        end


        //------------------------------------------------------
        // STOP
        //------------------------------------------------------

        rx = 1'b1;

        repeat(4)
        begin

            @(posedge clk);
            #1;

        end


        //------------------------------------------------------
        // IDLE
        //------------------------------------------------------

        rx = 1'b1;

    end

endtask


//==============================================================
// 24. INVALID STOP FRAME
//==============================================================

task send_invalid_stop_frame;

    input [7:0] frame_data;

    integer k;

    begin

        //------------------------------------------------------
        // IDLE
        //------------------------------------------------------

        rx = 1'b1;

        repeat(2)
        begin

            @(posedge clk);
            #1;

        end


        //------------------------------------------------------
        // START
        //------------------------------------------------------

        rx = 1'b0;

        repeat(6)
        begin

            @(posedge clk);
            #1;

        end


        //------------------------------------------------------
        // DATA
        //------------------------------------------------------

        for(k = 0; k < 8; k = k + 1)
        begin

            rx = frame_data[k];

            repeat(4)
            begin

                @(posedge clk);
                #1;

            end

        end


        //------------------------------------------------------
        // INVALID STOP
        //------------------------------------------------------

        rx = 1'b0;

        repeat(4)
        begin

            @(posedge clk);
            #1;

            // Capture framing-error pulse
            if(top_error === 1'b1)
                framing_error_seen = 1'b1;

        end


        //------------------------------------------------------
        // RETURN TO IDLE
        //------------------------------------------------------

        rx = 1'b1;

    end

endtask


//==============================================================
// 25. MAIN TEST SEQUENCE
//==============================================================

initial
begin

    pass_count = 0;
    fail_count = 0;

    reset = 1'b1;
    rx    = 1'b1;


    //==========================================================
    // TEST 1 - BASIC GATES
    //==========================================================

    $display("");
    $display("==================================================");
    $display("TEST 1 - BASIC GATES");
    $display("==================================================");

    gate_a = 1'b0;
    gate_b = 1'b0;
    #1;

    check_bit(gate_and_y,  1'b0, "AND 00");
    check_bit(gate_or_y,   1'b0, "OR 00");
    check_bit(gate_not_y,  1'b1, "NOT 0");
    check_bit(gate_xor_y,  1'b0, "XOR 00");
    check_bit(gate_nand_y, 1'b1, "NAND 00");
    check_bit(gate_nor_y,  1'b1, "NOR 00");


    gate_a = 1'b0;
    gate_b = 1'b1;
    #1;

    check_bit(gate_and_y,  1'b0, "AND 01");
    check_bit(gate_or_y,   1'b1, "OR 01");
    check_bit(gate_not_y,  1'b1, "NOT 0");
    check_bit(gate_xor_y,  1'b1, "XOR 01");
    check_bit(gate_nand_y, 1'b1, "NAND 01");
    check_bit(gate_nor_y,  1'b0, "NOR 01");


    gate_a = 1'b1;
    gate_b = 1'b0;
    #1;

    check_bit(gate_and_y,  1'b0, "AND 10");
    check_bit(gate_or_y,   1'b1, "OR 10");
    check_bit(gate_not_y,  1'b0, "NOT 1");
    check_bit(gate_xor_y,  1'b1, "XOR 10");
    check_bit(gate_nand_y, 1'b1, "NAND 10");
    check_bit(gate_nor_y,  1'b0, "NOR 10");


    gate_a = 1'b1;
    gate_b = 1'b1;
    #1;

    check_bit(gate_and_y,  1'b1, "AND 11");
    check_bit(gate_or_y,   1'b1, "OR 11");
    check_bit(gate_not_y,  1'b0, "NOT 1");
    check_bit(gate_xor_y,  1'b0, "XOR 11");
    check_bit(gate_nand_y, 1'b0, "NAND 11");
    check_bit(gate_nor_y,  1'b0, "NOR 11");


    //==========================================================
    // TEST 2 - HALF ADDER
    //==========================================================

    $display("");
    $display("==================================================");
    $display("TEST 2 - HALF ADDER");
    $display("==================================================");

    for(i = 0; i < 4; i = i + 1)
    begin

        ha_a = i[1];
        ha_b = i[0];

        #1;

        check_bit(ha_sum,   ha_a ^ ha_b, "HA SUM");
        check_bit(ha_carry, ha_a & ha_b, "HA CARRY");

    end


    //==========================================================
    // TEST 3 - FULL ADDER
    //==========================================================

    $display("");
    $display("==================================================");
    $display("TEST 3 - FULL ADDER");
    $display("==================================================");

    for(i = 0; i < 8; i = i + 1)
    begin

        fa_a   = i[2];
        fa_b   = i[1];
        fa_cin = i[0];

        #1;

        check_bit(
            fa_sum,
            fa_a ^ fa_b ^ fa_cin,
            "FA SUM"
        );

        check_bit(
            fa_carry,
            (fa_a & fa_b) |
            (fa_a & fa_cin) |
            (fa_b & fa_cin),
            "FA CARRY"
        );

    end


    //==========================================================
    // TEST 4 - 4-BIT INCREMENTER
    //==========================================================

    $display("");
    $display("==================================================");
    $display("TEST 4 - 4-BIT INCREMENTER");
    $display("==================================================");

    for(i = 0; i < 16; i = i + 1)
    begin

        inc_a = i[3:0];

        #1;

        check_4bit(
            inc_y,
            inc_a + 4'b0001,
            "INCREMENTER"
        );

    end


    //==========================================================
    // TEST 5 - RX SYNCHRONIZER
    //==========================================================

    $display("");
    $display("==================================================");
    $display("TEST 5 - RX SYNCHRONIZER");
    $display("==================================================");

    reset_all;

    sync_rx = 1'b0;

    @(posedge clk);
    #1;

    check_bit(
        sync_rx_out,
        1'b1,
        "SYNC FIRST STAGE DELAY"
    );

    @(posedge clk);
    #1;

    check_bit(
        sync_rx_out,
        1'b0,
        "SYNC OUTPUT LOW"
    );


    sync_rx = 1'b1;

    @(posedge clk);
    #1;

    @(posedge clk);
    #1;

    check_bit(
        sync_rx_out,
        1'b1,
        "SYNC OUTPUT HIGH"
    );


    //==========================================================
    // TEST 6 - BAUD COUNTER
    //==========================================================

    $display("");
    $display("==================================================");
    $display("TEST 6 - BAUD COUNTER");
    $display("==================================================");

    reset_all;

    baud_enable = 1'b1;

    @(posedge clk);
    #1;

    check_4bit(
        {2'b00, baud_count},
        4'b0001,
        "BAUD COUNT 1"
    );

    @(posedge clk);
    #1;

    check_4bit(
        {2'b00, baud_count},
        4'b0010,
        "BAUD COUNT 2"
    );

    @(posedge clk);
    #1;

    check_4bit(
        {2'b00, baud_count},
        4'b0011,
        "BAUD COUNT 3"
    );

    check_bit(
        baud_tick,
        1'b1,
        "BAUD TICK"
    );

    @(posedge clk);
    #1;

    check_4bit(
        {2'b00, baud_count},
        4'b0000,
        "BAUD ROLLOVER"
    );


    //==========================================================
    // TEST 7 - DATA REGISTER
    //==========================================================

    $display("");
    $display("==================================================");
    $display("TEST 7 - DATA REGISTER");
    $display("==================================================");

    reset_all;

    data_clear     = 1'b1;
    data_load      = 1'b0;
    data_bit_count = 3'd0;

    @(posedge clk);
    #1;

    data_clear = 1'b0;

    test_data = 8'hA5;

    for(i = 0; i < 8; i = i + 1)
    begin

        data_bit_count = i[2:0];
        rx             = test_data[i];
        data_load      = 1'b1;

        @(posedge clk);
        #1;

        data_load = 1'b0;

    end

    check_8bit(
        data_reg_out,
        8'hA5,
        "DATA REGISTER A5"
    );


    //==========================================================
    // TEST 8 - BIT COUNTER
    //==========================================================

    $display("");
    $display("==================================================");
    $display("TEST 8 - BIT COUNTER");
    $display("==================================================");

    reset_all;

    bit_clear = 1'b1;

    @(posedge clk);
    #1;

    bit_clear  = 1'b0;
    bit_enable = 1'b1;

    for(i = 0; i < 8; i = i + 1)
    begin

        @(posedge clk);
        #1;

    end

    check_4bit(
        {1'b0, bit_count},
        4'b0111,
        "BIT COUNT 7"
    );

    check_bit(
        bit_last,
        1'b1,
        "LAST BIT"
    );


    //==========================================================
    // TEST 9 - RX LOGIC
    //==========================================================

    $display("");
    $display("==================================================");
    $display("TEST 9 - RX LOGIC");
    $display("==================================================");

    logic_state     = 2'b00;
    logic_rx        = 1'b1;
    logic_baud_tick = 1'b0;

    #1;

    check_bit(
        logic_busy,
        1'b0,
        "LOGIC IDLE BUSY"
    );


    logic_rx = 1'b0;

    #1;

    check_bit(
        logic_clear_data,
        1'b1,
        "LOGIC CLEAR START"
    );


    logic_state     = 2'b10;
    logic_baud_tick = 1'b1;

    #1;

    check_bit(
        logic_sample_data,
        1'b1,
        "LOGIC SAMPLE DATA"
    );

    check_bit(
        logic_busy,
        1'b1,
        "LOGIC DATA BUSY"
    );


    logic_state     = 2'b11;
    logic_rx        = 1'b1;
    logic_baud_tick = 1'b1;

    #1;

    check_bit(
        logic_valid,
        1'b1,
        "VALID STOP"
    );

    check_bit(
        logic_error,
        1'b0,
        "NO FRAMING ERROR"
    );


    logic_rx = 1'b0;

    #1;

    check_bit(
        logic_valid,
        1'b0,
        "INVALID STOP VALID=0"
    );

    check_bit(
        logic_error,
        1'b1,
        "INVALID STOP ERROR=1"
    );


    //==========================================================
    // TEST 10 - FSM
    //==========================================================

    $display("");
    $display("==================================================");
    $display("TEST 10 - FSM");
    $display("==================================================");

    reset_all;

    fsm_rx        = 1'b1;
    fsm_baud_tick = 1'b0;
    fsm_last_bit  = 1'b0;

    @(posedge clk);
    #1;

    check_4bit(
        {2'b00, fsm_state},
        4'b0000,
        "FSM RESET IDLE"
    );


    fsm_rx = 1'b0;

    @(posedge clk);
    #1;

    check_4bit(
        {2'b00, fsm_state},
        4'b0001,
        "FSM START"
    );


    fsm_baud_tick = 1'b1;

    @(posedge clk);
    #1;

    check_4bit(
        {2'b00, fsm_state},
        4'b0010,
        "FSM DATA"
    );


    fsm_last_bit = 1'b1;

    @(posedge clk);
    #1;

    check_4bit(
        {2'b00, fsm_state},
        4'b0011,
        "FSM STOP"
    );


    //==========================================================
    // TEST 11 - RESET SAFETY
    //==========================================================

    $display("");
    $display("==================================================");
    $display("TEST 11 - RESET SAFETY");
    $display("==================================================");

    reset_all;

    check_8bit(
        struct_data,
        8'h00,
        "STRUCT RESET DATA"
    );

    check_8bit(
        rtl_data,
        8'h00,
        "RTL RESET DATA"
    );

    check_8bit(
        top_data,
        8'h00,
        "TOP RESET DATA"
    );

    check_bit(
        struct_busy,
        1'b0,
        "STRUCT RESET BUSY"
    );

    check_bit(
        rtl_busy,
        1'b0,
        "RTL RESET BUSY"
    );

    check_bit(
        top_busy,
        1'b0,
        "TOP RESET BUSY"
    );


    //==========================================================
    // TEST 12 - COMPLETE UART FRAME A5
    //==========================================================

    $display("");
    $display("==================================================");
    $display("TEST 12 - COMPLETE UART FRAME A5");
    $display("==================================================");

    reset_all;

    send_uart_frame(8'hA5);

    repeat(3)
    begin

        @(posedge clk);
        #1;

    end

    check_8bit(
        struct_data,
        8'hA5,
        "STRUCT DATA A5"
    );

    check_8bit(
        rtl_data,
        8'hA5,
        "RTL DATA A5"
    );

    check_8bit(
        top_data,
        8'hA5,
        "TOP DATA A5"
    );

    check_bit(
        struct_busy,
        1'b0,
        "STRUCT BUSY AFTER A5"
    );

    check_bit(
        rtl_busy,
        1'b0,
        "RTL BUSY AFTER A5"
    );

    check_bit(
        top_busy,
        1'b0,
        "TOP BUSY AFTER A5"
    );


    //==========================================================
    // TEST 13 - MULTIPLE DATA PATTERNS
    //==========================================================

    $display("");
    $display("==================================================");
    $display("TEST 13 - MULTIPLE UART DATA PATTERNS");
    $display("==================================================");


    reset_all;

    send_uart_frame(8'h00);

    repeat(3)
    begin @(posedge clk); #1; end

    check_8bit(top_data, 8'h00, "PATTERN 00");


    reset_all;

    send_uart_frame(8'hFF);

    repeat(3)
    begin @(posedge clk); #1; end

    check_8bit(top_data, 8'hFF, "PATTERN FF");


    reset_all;

    send_uart_frame(8'h55);

    repeat(3)
    begin @(posedge clk); #1; end

    check_8bit(top_data, 8'h55, "PATTERN 55");


    reset_all;

    send_uart_frame(8'hAA);

    repeat(3)
    begin @(posedge clk); #1; end

    check_8bit(top_data, 8'hAA, "PATTERN AA");


    reset_all;

    send_uart_frame(8'h3C);

    repeat(3)
    begin @(posedge clk); #1; end

    check_8bit(top_data, 8'h3C, "PATTERN 3C");


    reset_all;

    send_uart_frame(8'hC3);

    repeat(3)
    begin @(posedge clk); #1; end

    check_8bit(top_data, 8'hC3, "PATTERN C3");


    //==========================================================
    // TEST 14 - BACK-TO-BACK FRAMES
    //==========================================================

    $display("");
    $display("==================================================");
    $display("TEST 14 - BACK-TO-BACK FRAMES");
    $display("==================================================");

    reset_all;

    send_uart_frame(8'h3C);

    repeat(3)
    begin @(posedge clk); #1; end

    check_8bit(
        top_data,
        8'h3C,
        "BACK-TO-BACK FIRST"
    );


    send_uart_frame(8'hC3);

    repeat(3)
    begin @(posedge clk); #1; end

    check_8bit(
        top_data,
        8'hC3,
        "BACK-TO-BACK SECOND"
    );


    //==========================================================
    // TEST 15 - INVALID STOP / FRAMING ERROR
    //==========================================================

    $display("");
    $display("==================================================");
    $display("TEST 15 - INVALID STOP");
    $display("==================================================");

    reset_all;

    framing_error_seen = 1'b0;

    send_invalid_stop_frame(8'hA5);

    #1;

    check_bit(
        framing_error_seen,
        1'b1,
        "FRAMING ERROR DETECTED"
    );


    //==========================================================
    // TEST 16 - STRUCTURAL VS RTL
    //==========================================================

    $display("");
    $display("==================================================");
    $display("TEST 16 - STRUCTURAL VS RTL");
    $display("==================================================");

    reset_all;

    send_uart_frame(8'h5A);

    repeat(3)
    begin

        @(posedge clk);
        #1;

    end

    check_8bit(
        struct_data,
        rtl_data,
        "STRUCT VS RTL DATA"
    );

    check_bit(
        struct_busy,
        rtl_busy,
        "STRUCT VS RTL BUSY"
    );

    check_bit(
        struct_valid,
        rtl_valid,
        "STRUCT VS RTL VALID"
    );

    check_bit(
        struct_error,
        rtl_error,
        "STRUCT VS RTL ERROR"
    );


    //==========================================================
    // TEST 17 - FINAL IDLE SAFETY
    //==========================================================

    $display("");
    $display("==================================================");
    $display("TEST 17 - FINAL IDLE SAFETY");
    $display("==================================================");

    rx = 1'b1;

    repeat(5)
    begin

        @(posedge clk);
        #1;

    end

    check_bit(
        top_busy,
        1'b0,
        "FINAL BUSY = 0"
    );

    check_bit(
        top_valid,
        1'b0,
        "FINAL VALID = 0"
    );

    check_bit(
        top_error,
        1'b0,
        "FINAL ERROR = 0"
    );


    //==========================================================
    // FINAL REPORT
    //==========================================================

    $display("");
    $display("==================================================");
    $display("DAY 19 UART RECEIVER TEST COMPLETE");
    $display("==================================================");

    $display("TOTAL PASS = %0d", pass_count);
    $display("TOTAL FAIL = %0d", fail_count);


    if(fail_count == 0)
    begin

        $display("");
        $display("**********************************************");
        $display("*          ALL TESTS PASSED                 *");
        $display("*      DAY 19 UART RX VERIFIED              *");
        $display("**********************************************");
        $display("");

    end

    else
    begin

        $display("");
        $display("**********************************************");
        $display("*          TESTS FAILED                     *");
        $display("*      CHECK FAILURES ABOVE                 *");
        $display("**********************************************");
        $display("");

    end


    $finish;

end


//==============================================================
// 26. WAVEFORM DUMP
//==============================================================

initial
begin

    $dumpfile("day19_uart_rx.vcd");

    $dumpvars(0, day19_tb);

end


endmodule