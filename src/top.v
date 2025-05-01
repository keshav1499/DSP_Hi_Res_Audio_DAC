module top( 

input clk,
input btn1,
output data,
output bck,
output mute,
output ws 
);


driver dvr(

.clk(clk),
.btn1(btn1),
.data(data),
.bck(bck),
.ws(ws)
);





endmodule