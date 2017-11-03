// Register module
module Register(read1, read2, data, clk, wrtEn, wrtAdd, out1, out2);

output signed [31:0] out1, out2;

reg signed [31:0] index [31:0];

input clk, wrtEn;

input signed [31:0] data;

input [4:0] read1, read2;
input [4:0] wrtAdd;

integer i;
initial
begin
for (i = 0; i < 32; i = i + 1)
index[i] = i;
end

assign out1 = index[read1];
assign out2 = index[read2];

always @ (posedge clk)
begin

if (wrtEn == 1)
begin
index[wrtAdd] <= data;
end

end


endmodule

// ALU Register
module ALU (Result, overflow, lessthan, A, B, shft, op);

output signed [31:0] Result;
output overflow;
output lessthan;

input signed [31:0] A, B;
input [3:0] op;
input [4:0] shft;
//input mode;

wire signed [31:0] B_negated;

assign B_negated = - B;

/*
0 : add , 
1 : sub , 
2 : and , 
3 : or, 
4 : shift left , 
5 : shift right logical, 
6: shift right arithmetic, 
7 : greater_than , 
8 : less_than
*/

assign Result = (op == 4'b0000)? (A + B):
(op == 4'b0001)? (A - B) : 
(op == 4'b0010)? (A & B) : 
(op == 4'b0011)? (A | B) : 
(op == 4'b0100)? (A<<shft) : 
(op == 4'b0101)? (A>>shft) : 
(op == 4'b0110)? $signed(($signed(A)>>>shft)) : 
(op == 4'b0111)? (A>B)? A : B : 
(op == 4'b1000)? ((A<B)? B : A) :
1'bx;

assign lessthan = (op == 4'b0111)? (A>B)? A : B : 
(op == 4'b1000)? ((A<B)? B : A) :
1'bx;

//A[31]==B[31] && A[31] != Result[31]; //+

//A[31]==B_negated[31] && A[31] != Result[31]; //-

assign overflow = (op == 4'b0000 && A[31]==B[31] && A[31] != Result[31]) ? 1'b1 :
(op == 4'b0001 && A[31]==B_negated[31] && A[31] != Result[31]) ? 1'b1:
1'bx;

/*
if ((op == 4'b0000 && A>=0 && B>=0 && Result<0) || (op == 4'b0000 && A<0 && B<0 && Result>=0))
begin
overflow = 1'b1;
end
else if ((op == 4'b0001 && A>=0 && B<0 && Result<0) || (op == 4'b0001 && A>0 && B>=0 && Result>=0))
begin
overflow = 1'b1;
end
else
begin
overflow = 1'b0;
end
*/
endmodule


// Mux
module mux (z, x, y, sel);

/*
assign z = (~sel * ~y * x) + (~sel * y * x) + (sel * y * ~x)
+ (sel * y * x);
*/

output signed [31:0] z;
input signed [31:0] x, y;
input sel;

assign z = (sel == 0)? x: y;
/*
always@(x or y or sel)
begin
if (sel == 0)
begin
z = x;
end
else if (sel == 1)
begin
z = y;
end
else
begin
z = 1'bx;
end
end
*/
endmodule

// Register test module
module testReg();

wire [31:0] out1, out2;


reg clk, wrtEn;

reg [31:0] data;

reg [4:0] read1, read2;
reg [4:0] wrtAdd;


initial
fork

$monitor("read1=%b, read2= %b, out1= %b, out2= %b, wrtAdd= %b", read1, read2, out1, out2, wrtAdd);

clk = 0;
wrtEn = 1;

forever
begin 
#1 
clk =~ clk;
end

#15 
wrtAdd<=2; data<=4;
#30 
wrtAdd<=8; data<=6;
#40 
read1<=8; read2<=6;
#50 
wrtAdd<=13; 
data<=3; 
read1<=2; read2<=1;
#60 
wrtAdd<=13;

join
Register reg1(read1, read2, data, clk, wrtEn, wrtAdd, out1, out2);

endmodule

// ALU test module
module tb();

reg [31:0] A, B;
reg [3:0] op;
reg [4:0] shft;
reg mode;

wire [31:0] Result;
wire overflow;
wire lessthan;

ALU alu (Result, overflow, lessthan, A, B, shft, op);

initial
begin

// 4 + 2
A<=4000000000;
B<=4000000000;
op = 4'b0000;

$monitor ("op = %b, A = %b, B = %b, Result = %b, Overflow = %b, Lessthan = %b", op, A, B, Result, overflow, lessthan);

#5 
// 6 + 7
A<=6;
B<=7;
op = 4'b0000;

#5
// -4 + (-2) = -6
A<=-4;
B<=-2;
op = 4'b0000;

#5
// -3 + 4 = -1 
A<=-3;
B<=4;
op = 4'b0000;

#5 
// -6 - 7 = 11
A<=13;
B<=14;
op = 4'b0000;

end

endmodule

// MUX test module
module MuxTest;

reg x, y, sel;
wire z;

initial
begin

$monitor("%b %b %b %b", sel, x, y, z);

#5
sel = 0;
x = 0;
y = 1;

#5
x = 1;
y =0;

#5
sel = 1;
y = 1;
x = 0;
#5
y = 0;
x = 1;
end

mux m1 (z, x, y, sel);

endmodule




// Final test module
module final();

reg clk, wrtEn;

reg signed [31:0] data;

reg [4:0] read1, read2;
reg [4:0] wrtAdd;

reg signed [31:0] MUX_Input1;
reg MUX_Sel;
wire signed [31:0] MUX_Result;

wire signed [31:0] RegOut1, RegOut2;
reg [3:0] op;
reg [4:0] shft;

wire signed [31:0] ALU_Result;
wire overflow;
wire lessthan;


always 
begin
#2 clk = ~clk;
end

initial
begin

#10
clk = 1;
MUX_Sel <= 0;
wrtEn <= 1;
wrtAdd <= 2; MUX_Input1 <= 4;
wrtAdd <= 4; MUX_Input1 <= 8;
wrtAdd <= 5; MUX_Input1 <= 10;
wrtAdd <= 6; MUX_Input1 <= 12;
wrtAdd <= 10; MUX_Input1 <= -20;

#5 wrtAdd <= 2; MUX_Input1 <= 4;
$monitor("Write Address: %b  , Value = %d",wrtAdd, MUX_Input1);

#5 read1<=2;
$monitor("Read Address: %b  , Value = %d",read1, RegOut1);

#5 op<=0;read1<=5;read2<=6;
$monitor("%d + %d = %d",RegOut1, RegOut2, ALU_Result);

#5 op<=1;read1<=6;read2<=5;
$monitor("%d - %d = %d",RegOut1,RegOut2,ALU_Result);

#5 op<=2;read1<=6;read2<=7;
$monitor("%d & %d = %d",RegOut1,RegOut2,ALU_Result);

#5 op<=3;read1<=7;read2<=6;
$monitor("%d | %d = %d",RegOut1,RegOut2,ALU_Result);

#5 op<=4;read1<=7;shft<=1;
$monitor("%d shiftLeft %d",RegOut1,ALU_Result);

#5 op<=5;read1<=8;
$monitor("%d shiftRight %d",RegOut1,ALU_Result);

#5 op<=6;read1<=10;
$monitor("%d shiftRightA r %d",RegOut1,ALU_Result);

#5 op<=7;read1<=10;read2<=9;
$monitor("%d > %d = %d",RegOut1,RegOut2,ALU_Result);

#5 op<=8;read1<=5;read2<=9;
$monitor("%d < %d = %d",RegOut1,RegOut2,ALU_Result);

end

/*
$monitor("RegWrite -- Data= %b, Address= %b", MUX_Result, wrtAdd);
#10
clk = 1;
wrtEn = 1;
wrtAdd = 1;
MUX_Input1 = 3;
MUX_Sel = 0;
#10
wrtAdd = 2;
MUX_Input1 = 6;
MUX_Sel = 0;
#10
read1<=1;
read2<=2;
$monitor("Read1= %b, Read2= %b, RegOut1= %b, RegOut2= %b", read1, read2, RegOut1, RegOut2);
#10
read1<=1;
read2<=2;
end
*/
mux mux1(MUX_Result, MUX_Input1, ALU_Result, MUX_Sel);
Register reg1(read1, 
read2, 
MUX_Result, 
clk, 
wrtEn, 
wrtAdd, 
RegOut1, 
RegOut2);

ALU alu(ALU_Result, 
overflow, 
lessthan, 
RegOut1, 
RegOut2, 
shft, 
op);

endmodule