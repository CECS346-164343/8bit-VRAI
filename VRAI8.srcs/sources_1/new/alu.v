/*
 * 8-bit VRAI-inspired ALU for educational use. The goal is modular,
 * easy-to-follow code. This module implements the ALU operation set, not
 * every CPU instruction.
 *
 * ALU function codes: note, these are subject to change in the future if i choose to add additional fuctions
 *   0 ADD   
 *   1 ADC
 *   2 AND
 *   3 OR
 *   4 NOR
 *   5 CMP   
 *   6 SBB   
 *   7-8 reserved 
 *   
 * @param opcode        4-bit code selecting the ALU operation
 * @param operand_a     First 8-bit data operand
 * @param operand_b     Second 8-bit data operand
 * @param carry_in      Carry input for ADC or borrow input for SBB
 * @param result        8-bit result produced by the ALU
 * @param result_write  Whether to write the result to a register
 *
 * @param z_write Whether to update the zero flag
 * @param c_write Whether to update the carry/borrow flag
 * @param z_value New value for the zero flag
 * @param c_value New value for the carry/borrow flag
 */
module alu (
    input wire [3:0] opcode,
    input wire [7:0] operand_a,
    input wire [7:0] operand_b,
    input wire carry_in,
    output reg [7:0] result,
    output reg result_write,
    output reg z_write,
    output reg c_write,
    output reg z_value,
    output reg c_value
);
    reg [8:0] sum;
    reg [8:0] rhs;
    reg [8:0] difference;
    reg borrow;

    always @* begin
        result = 8'h00;
        result_write = 1'b0;
        z_write = 1'b0;
        c_write = 1'b0;
        z_value = 1'b0;
        c_value = carry_in;
        sum = 9'h000;
        rhs = 9'h000;
        difference = 9'h000;
        borrow = 1'b0;

        case (opcode)
            4'h0: begin // ADD
                // the 9th bit preserves cout; easy to follow
                sum = {1'b0, operand_a} + {1'b0, operand_b};
                result = sum[7:0];
                result_write = 1'b1;
                z_write = 1'b1;
                c_write = 1'b1;
                z_value = (sum[7:0] == 8'h00);
                c_value = sum[8];
            end
            4'h1: begin // ADC: add with carry
                sum = {1'b0, operand_a} + {1'b0, operand_b} + carry_in;
                result = sum[7:0];
                result_write = 1'b1;
                z_write = 1'b1;
                c_write = 1'b1;
                z_value = (sum[7:0] == 8'h00);
                c_value = sum[8];
            end
            4'h2: begin // AND
                result = operand_a & operand_b;
                result_write = 1'b1;
                z_write = 1'b1;
                z_value = (result == 8'h00);
            end
            4'h3: begin // OR
                result = operand_a | operand_b;
                result_write = 1'b1;
                z_write = 1'b1;
                z_value = (result == 8'h00);
            end
            4'h4: begin // NOR
                result = ~(operand_a | operand_b);
                result_write = 1'b1;
                z_write = 1'b1;
                z_value = (result == 8'h00);
            end
            4'h5: begin // CMP unsigned A - B, flags only
                result_write = 1'b0;
                z_write = 1'b1;
                c_write = 1'b1;
                z_value = (operand_a == operand_b);
                c_value = (operand_a < operand_b);
            end
            4'h6: begin // SBB: subtract with borrow
                // 9 bits allow rhs to represent 256 when b=255 and cin=1; wrap around
                rhs = {1'b0, operand_b} + carry_in;
                difference = {1'b0, operand_a} - rhs;
                borrow = ({1'b0, operand_a} < rhs);
                result = difference[7:0];
                result_write = 1'b1;
                z_write = 1'b1;
                c_write = 1'b1;
                z_value = (difference[7:0] == 8'h00);
                c_value = borrow;
            end
            4'h7, 4'h8: begin
                // Reservedno result or flag updates for now
            end
            default: begin
                // Other func can be reserved. we'll see
            end
        endcase
    end
endmodule
