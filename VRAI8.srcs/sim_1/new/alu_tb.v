`timescale 1ns/1ps

// Exhaustive combinational testbench for ALU-local function codes 0 through 8.
module alu_tb;
    reg [3:0] opcode;
    reg [7:0] operand_a;
    reg [7:0] operand_b;
    reg carry_in;
    wire [7:0] result;
    wire result_write;
    wire z_write;
    wire c_write;
    wire z_value;
    wire c_value;

    integer opcode_i;
    integer a_i;
    integer b_i;
    integer carry_i;
    integer test_count;
    integer failures;

    alu dut (
        .opcode(opcode),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .carry_in(carry_in),
        .result(result),
        .result_write(result_write),
        .z_write(z_write),
        .c_write(c_write),
        .z_value(z_value),
        .c_value(c_value)
    );

    // use one vector, calculate expected outputs, and compare 

    task check_vector;
        input [3:0] op;
        input [7:0] a;
        input [7:0] b;
        input cin;
        reg [8:0] expected_sum;
        reg [8:0] expected_rhs;
        reg [8:0] expected_difference;
        reg [7:0] expected_result;
        reg expected_result_write;
        reg expected_z_write;
        reg expected_c_write;
        reg expected_z;
        reg expected_c;
        begin
            opcode = op;
            operand_a = a;
            operand_b = b;
            carry_in = cin;

            expected_result = 8'h00;
            expected_result_write = 1'b0;
            expected_z_write = 1'b0;
            expected_c_write = 1'b0;
            expected_z = 1'b0;
            expected_c = cin;
            case (op)
                4'h0, 4'h1: begin // ADD and ADC
                    expected_sum = {1'b0, a} + {1'b0, b};
                    if (op == 4'h1)
                        expected_sum = expected_sum + cin;

                    expected_result = expected_sum[7:0];
                    expected_result_write = 1'b1;
                    expected_c_write = 1'b1;
                    expected_c = expected_sum[8];
                end
                4'h2, 4'h3, 4'h4: begin // AND, OR, and NOR
                    case (op)
                        4'h2: expected_result = a & b;
                        4'h3: expected_result = a | b;
                        4'h4: expected_result = ~(a | b);
                    endcase
                    expected_result_write = 1'b1;
                end
                4'h5: begin // CMP
                    expected_z_write = 1'b1;
                    expected_c_write = 1'b1;
                    expected_z = (a == b);
                    expected_c = (a < b);
                end
                4'h6: begin // SBB
                    expected_rhs = {1'b0, b} + cin;
                    expected_difference = {1'b0, a} - expected_rhs;
                    expected_result = expected_difference[7:0];
                    expected_result_write = 1'b1;
                    expected_c_write = 1'b1;
                    expected_c = ({1'b0, a} < expected_rhs);
                end
                default: begin
                    // No ALU op is selected.
                end
            endcase

            // update result
            if (expected_result_write) begin
                expected_z_write = 1'b1;
                expected_z = (expected_result == 8'h00);
            end

            #10;
            test_count = test_count + 1;
            if ({result, result_write, z_write, c_write, z_value, c_value} !==
                {expected_result, expected_result_write, expected_z_write,
                 expected_c_write, expected_z, expected_c}) begin
                failures = failures + 1;
                // Cap diagnostics so a broken ALU does not flood the console.
                if (failures <= 10) begin
                    $display("FAIL op=%h A=%02h B=%02h Cin=%b: got R=%02h RW=%b ZW=%b CW=%b Z=%b C=%b",
                             op, a, b, cin, result, result_write, z_write,
                             c_write, z_value, c_value);
                    $display("                   expected: R=%02h RW=%b ZW=%b CW=%b Z=%b C=%b",
                             expected_result, expected_result_write,
                             expected_z_write, expected_c_write,
                             expected_z, expected_c);
                end
            end
        end
    endtask

    initial begin
        test_count = 0;
        failures = 0;

        // test the full 0-8 code space, every operand pair, and both carry-in
        // values. Codes 7 and 8 are reserved and are checked by the default model.
        // 9 codes * 256 A values * 256 B values * 2 carry values = 1,179,648, a lil od
        // runtime is capped 
        // TCL console 'run 1000ns' at a time since vivado caps tb time 
        for (opcode_i = 0; opcode_i <= 8; opcode_i = opcode_i + 1) begin
            for (a_i = 0; a_i < 256; a_i = a_i + 1) begin
                for (b_i = 0; b_i < 256; b_i = b_i + 1) begin
                    for (carry_i = 0; carry_i < 2; carry_i = carry_i + 1) begin
                        check_vector(opcode_i, a_i, b_i, carry_i);
                    end
                end
            end
        end

        if (failures == 0) begin
            $display("PASS: all %0d ALU vectors passed", test_count);
            $finish;
        end else begin
            $fatal(1, "ALU testbench failed: %0d of %0d vectors", failures, test_count);
        end
    end
endmodule

