module top( 

input clk,
input btn1,
output data,
output bck,
output mute,
output ws 
);

/*The below driver works for UDA344A DAC only
also keep in mind it is I2S only*/
driver dvr(

.clk(clk),
.btn1(btn1),
.data(data),
.bck(bck),
.ws(ws),
.mute(mute)
);




endmodule
