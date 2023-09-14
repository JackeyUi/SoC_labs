Study Journal of SOC design labs.
===
Lab 1:   
===
關於Linux檔案權限可以使用chmod指令來進行調整。  
parts: xc7z020clg400-1

整體流程:  
>1. 在Vitis建立專案，丟入C/C++檔案，建立directive，並開始sim和syn(或cosim驗證).  
>2. Export RTL，匯出到Vivado進行下一步  
>3. 在Vivado import在Vitis建立的IP  
>4. Create Block Design，並在diagram tab加入元件  
>5. 調整Configuration，建立Connection(可以善用自動化)  
>6. 在Sources視窗建立HDL Wrapper。
>7. 建立Bitstream*  
>8. 用MOBA租借FPGA版，把相關檔案(bit, hwh, python code)上傳後到Jupyter Notebook後，就可執行。
>
>*:在Linux下進行，Bitstream檔需在Vivado專案所在處找。  
>bit檔位於./xxx.runs/impl_1，  
>hwh檔位於./xxx.gen/sources_1/bd/yyy/hw_handoff。



Multiplication.h defines valuable: n32In1, n32In2m and pn32ResOut (pointer).  
Multiplication.cpp with the valuable pragmas, and has a line to assign the output: 

> *pn32ResOut = n32In1 * n32In2;

About the ap_ctrl_none:

>https://docs.xilinx.com/r/2022.1-English/ug1399-vitis-hls/Using-ap_ctrl_none-Inside-the-Dataflow

Note that when doing Cosim , the following error occurs: 

> ERROR: [COSIM 212-345] Cosim only supports the following 'ap_ctrl_none' designs: (1) combinational designs; (2) pipelined 
design with II of 1; (3) designs with array streaming or hls_stream or AXI4 stream ports.

We should be careful about the ap_ctrl setting before Cosim.

在觀察波型時，可以利用Go to source code，和Object視窗去尋找reg訊號，有些訊號可能沒有列在top design裡。

Lab 2  
===
