`timescale 10ps / 1ps
(* use_dsp = "no" *)
module fir 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)
(
    output  wire                     awready,
    output  wire                     wready,
    input   wire                     awvalid,
    input   wire [(pADDR_WIDTH-1):0] awaddr,
    input   wire                     wvalid,
    input   wire [(pDATA_WIDTH-1):0] wdata,
    
    output  wire                     arready,
    input   wire                     rready,
    input   wire                     arvalid,
    input   wire [(pADDR_WIDTH-1):0] araddr,
    output  wire                     rvalid,
    output  wire [(pDATA_WIDTH-1):0] rdata,  
      
    input   wire                     ss_tvalid, 
    input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
    input   wire                     ss_tlast, 
    output  wire                     ss_tready, 
    
    input   wire                     sm_tready, 
    output  wire                     sm_tvalid, 
    output  wire [(pDATA_WIDTH-1):0] sm_tdata, 
    //output  wire [(pDATA_WIDTH-1):0] sm_temp,
    output  wire                     sm_tlast, 
    
    // bram for tap RAM
    output  wire [3:0]               tap_WE,
    output  wire                     tap_EN,
    output  wire [(pDATA_WIDTH-1):0] tap_Di,
    output  wire [(pADDR_WIDTH-1):0] tap_A, 
    input   wire [(pDATA_WIDTH-1):0] tap_Do,

    // bram for data RAM
    output  wire [3:0]               data_WE,
    output  wire                     data_EN,
    output  wire [(pDATA_WIDTH-1):0] data_Di,
    output  wire [(pADDR_WIDTH-1):0] data_A,
    input   wire [(pDATA_WIDTH-1):0] data_Do,

    input   wire                     axis_clk,
    input   wire                     axis_rst_n
    
);
begin
    
    
    reg [31:0] status;
    reg [31:0] cnt, datalength;
    
    reg writing, awriting; 
    reg rr;  // pause wready
    reg sswait; 
    reg smset;
    reg WaitRD;
    reg Done;
    reg last;
    reg backp;
    reg [31:0] temp, result;
    reg init;
    reg [5:0] readptr;
    reg [5:0] dreadptr;
    
    initial begin
        readptr = 0;
        dreadptr = Tape_Num - 1;
        datalength = 0;
        cnt = 0;
        last = 0;
        sswait = 0;
        smset = 0;
        rr = 0;
        writing = 0; awriting = 0;
        init = 1;
        status = 32'b0;
        status[0] = 0; // start
        status[1] = 0; // done
        status[2] = 1; //idle
    end
    
    

    
    always@(posedge axis_clk or negedge axis_rst_n ) begin
        if (!axis_rst_n)begin
            result <= 0;
        end 
        else if (Done & !smset ) begin
            result <= temp + data_Do * tap_Do;
        end else if (backp & sm_tvalid && sm_tready) begin
            result <= temp;
        end
        else begin
            result <= result;
        end
        
    end
    
    
    always@(posedge axis_clk or negedge axis_rst_n ) begin
        if (!axis_rst_n)begin
            backp <= 0;
        end 
        else if (sm_tvalid && sm_tready) begin
            backp <= 0;
        end 
        else if (smset && readptr == 4'd10) begin
            backp <= 1;
        end
        else begin
            backp <= backp;
        end
        
    end
    
    
    
    

    assign ss_tready = (!status[2] && !sswait && !init && !last && !backp) ? 1 : 0;
    
   
    
    always@(posedge axis_clk or negedge axis_rst_n ) begin
        if (!axis_rst_n)begin
            last <= 0;
        end 
        else if (status[0]) begin
            last <= 0;
        end 
        else if (cnt == datalength) begin
            last <= 1;    
        end else begin
            last <= last;
        end
        
    end
    
        always@(posedge axis_clk or negedge axis_rst_n ) begin
        if (!axis_rst_n)begin
            WaitRD <= 0;
        end 
        else if (ss_tready && ss_tvalid ) begin
            WaitRD <= 1;
        end 
        else begin
            WaitRD <= 0;
        end
        
    end
    
    always@(posedge axis_clk or negedge axis_rst_n ) begin
        if (!axis_rst_n)begin
            Done <= 0;
        end 
        else if (readptr == 4'd10 && sswait) begin
            Done <= 1;
        end 
        else begin
            Done <= 0;
        end
        
    end
    
    
    always@(posedge axis_clk or negedge axis_rst_n ) begin
        if (!axis_rst_n)begin
            sswait <= 0;
        end else if (ss_tready && ss_tvalid) begin
            sswait <= 1;
        end else if (readptr == 4'd10 && sswait) begin
            sswait <= 0;
        end else sswait <= sswait;
    end
    
    always@(posedge axis_clk or negedge axis_rst_n ) begin
        if (!axis_rst_n)begin
            smset <= 0;
        end else if (backp) begin
            smset <= 1;       
        end else if (sm_tvalid  && sm_tready) begin
            smset <= 0;
        end else if (Done) begin
            smset <= 1;
        end else smset <= smset;
    end
    
    
    always@(posedge axis_clk or negedge axis_rst_n ) begin
        if (!axis_rst_n)begin
            cnt <= 0;
        end else if (status[0]) begin
            cnt <= 0;
        end else if (ss_tready && ss_tvalid) begin
            cnt <= cnt + 1;
        end else cnt <= cnt;
    end
    
    always@(posedge axis_clk or negedge axis_rst_n ) begin
        if (!axis_rst_n)begin
            temp <= 0;
        end else if (WaitRD)begin
            temp <= data_Do * tap_Do;
        end else if (sswait ) begin
            temp <= temp + data_Do * tap_Do ;
        end else temp <= temp;
    end
    
    
    assign sm_tvalid = (smset) ? 1 : 0; //#
    assign sm_tlast = (smset && last) ? 1 : 0;

    assign data_Di =(init) ? 0: 
                    (ss_tready ) ? ss_tdata : 
                    (sswait) ? sm_tdata : 0;
                    
    assign data_A =  (init) ? dreadptr << 2:
                    (!status[2]) ? dreadptr<<2 : 0;

    assign data_WE = (init) ? 4'b1111 :
                     (ss_tready && ss_tvalid) ? 4'b1111 :
                     (sswait) ? 4'b0 : 0;
                     
    assign data_EN = (init) ? 1:
                     (!status[2]) ? 1:0;
                    
    //assign sm_temp = temp;
    assign sm_tdata = result;

    always@(posedge axis_clk or negedge axis_rst_n ) begin
        if (!axis_rst_n )begin
            readptr <= 0;
        //end else if (smset && readptr == 4'd10) begin
        //    readptr <= readptr;
        end else if (readptr == 4'd10) begin
            readptr <= 0;
        end else if (((ss_tready && ss_tvalid) || sswait) && (readptr != 4'd10))begin
            readptr <= readptr + 1;
        end else begin
            readptr <= readptr;
        end
      
    end
    
//    
    always@(posedge axis_clk or negedge axis_rst_n ) begin
        if (!axis_rst_n )begin
            dreadptr <= Tape_Num - 1;
        end else if (status[0]) begin
            dreadptr <= Tape_Num - 1;
        end else if (dreadptr == 0 && init) begin
            dreadptr <= 0; 
        end else if (init) begin
            dreadptr <= dreadptr - 1;
        //end else if (smset) begin
        //    dreadptr <= dreadptr;
        end else if (dreadptr == 0 && (((ss_tready && ss_tvalid) || sswait ) && readptr != 4'd10)) begin
            dreadptr <= Tape_Num - 1;
        end else if (((ss_tready && ss_tvalid) || sswait) && readptr != 4'd10)begin
            dreadptr <= dreadptr - 1;
        end else begin
            dreadptr <= dreadptr;
        end
      
    end
    
    always@(posedge axis_clk or negedge axis_rst_n ) begin
        if (!axis_rst_n )begin
            init <= 1;
        end else if (status[0]) begin
            init <= 1;
        end else if (dreadptr == 0) begin
            init <= 0;
        end else init <= init;
    end    
    
    
    assign awready = (!awriting)? 1:0;
    assign wready = (!writing)? 1:0;
    
    always@(posedge axis_clk or negedge axis_rst_n ) begin
        if (!axis_rst_n) begin
            awriting <= 0;
        end else if (awready && awvalid && status[2]) begin
            awriting <= 1;
        end else if (awriting && writing ) begin
            awriting <= 0;
        end else begin
            awriting <= awriting ;
        end
    end
    
    always@(posedge axis_clk or negedge axis_rst_n ) begin
        if (!axis_rst_n) begin
            writing <= 0;
        end else if (wready && wvalid& & status[2]) begin
            writing <= 1;
        end else if (awriting && writing ) begin
            writing <= 0;
        end else begin
            writing <= writing ;
        end
    end
    
    
    assign tap_Di = (!status[2] && !init) ? 4'b0 :
                    (writing) ? wdata : 0;
                    
    assign tap_A =  (!status[2] && !init) ? readptr<<2:
                    (awriting && awaddr  >= 12'h20 ) ? awaddr -12'h20:
                    (arready && arvalid ) ? araddr - 12'h20: 0; 
                    
    assign tap_WE = (!status[2] && !init) ? 4'b0 :
                    (writing) ? 4'b1111 : 0;
                    
    assign tap_EN = (!status[2] && !init) ? 1:
                    (writing && awaddr >= 12'h20) ? 1:
                    (rvalid && araddr >= 12'h20) ? 1 : 0;

    always@(posedge axis_clk or negedge axis_rst_n ) begin
        if (!axis_rst_n) begin
            datalength  <= 0;
        end 
        else if ( awaddr == 12'h10 && awriting && writing) begin
            datalength <= wdata;
        end 
        else datalength <= datalength ;
    end
/// status control
    always@(posedge axis_clk or negedge axis_rst_n ) begin
        if(!axis_rst_n) begin
            status[0] <= 0; // start
            status[2] <= 1; //idle
        end else if (sm_tlast) begin
            status[0] <= 0;
            status[2] <= 1;
        end else if (awaddr == 12'h0 && wvalid && awvalid && status[2]) begin
            status[0] <= wdata[0]; // set ap_start if programme
            status[2] <= status[2];
        end else if (status[0]) begin
            status[0] <= 0;
            status[2] <= 0;
        end else begin
            status [0] <= status[0];
            status [2] <= status[2];
        end
    end
    
    always@(posedge axis_clk or negedge axis_rst_n ) begin
        if(!axis_rst_n) begin
            status[1] <= 0;
        end
        else if (sm_tlast && sm_tvalid && sm_tready) begin
            status[1] <= 1;          // set ap_done after last output is transferred
        end else if (araddr == 12'h0 && rready  && rvalid ) begin
            status[1] <= 0;         // reset ap_done after status being read
        end else begin
            status[1] <= status[1];
        end
    end
/// write control done        
        
/// read control
    always@(posedge axis_clk or negedge axis_rst_n ) begin
        if (!axis_rst_n ) begin 
            rr = 0;
        end else if (arvalid && arready) begin
            rr = 1;
        end else if (rvalid && rready) begin
            rr = 0;
        end else begin
            rr = rr;
        end
    end


    assign arready = (!rr) ? 1 :0;
    assign rvalid = (rr) ? 1 : 0;
     
    
    
    assign rdata = (rvalid && araddr == 12'h0) ? status :  
                   (rvalid && araddr == 12'h10) ? datalength:
                   (rvalid && araddr >= 12'h20) ? tap_Do: 0 ;
    
    

end
endmodule 
