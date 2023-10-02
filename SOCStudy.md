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
parts: xc7z020clg400-1

整體流程:
>1. 建立專案，複製檔案到相對位置 → add new
source, testbench, top function (設定要與c code裡面一樣)→ directives → C simulation → C synthesis →
Export RTL
>2. 


FIR.cpp組成:  
fir_n11_maxi含有三個inputs, 一個output  
inputs:  
\*pn32HPInput: input data(此testbench為 從1到75，再下降到-75，再往上到75，每一步都差1。)  
an32Coef[MAP_ALIGN_4INT]: taps，為運算用參數  
regXferLeng: 輸入總bit數  
output:  
pn32HPOutput: 乘累加的最後結果  

此code運行是將輸入存入register，並用pipeline的方式對an32Coef進行乘法，最後進行累加，累加結果就是輸出。  
至於PYNQ的結果，則可以分析an32Coef的設計，可以注意到，an32Coef配上convultion的算法，可以發現這是一個延遲4個cycle，並且有個DC gain (約183) 的結果。這是因為input data是等差增加(到75)或減少(到-75)的，使乘累加的結果也是等差。  

STREAM區別:
由於加入了DMA的設計，input跟output是data一組一組的讀寫，因此需要增加了跟DMA的溝通command:  
> line 24 value_t valTemp = pstrmInput->read();  
> line 38 pstrmOutput->write(valTemp);  
> line 39 if (valTemp.last) break;  


DMA Block diagram: 要注意in要enable read channel, out要enable write channel.  

遇到問題: 
>1. 檔名不對: 請記得上傳所有需要用到的檔案，並確認python code的檔名。
>2. 路徑問題: 目錄用\\取代\，路徑才會正確，並可以用絕對路徑。
>3. fc和diff: fc是用於Windows上的指令，用來比對兩個檔案差異，diff則是用於Linux
//>4. FIRTester Co-sim出現error: 由於FIRTester.cpp 會建一個NUM_SAMPLES * sizeof(int32_t) 的valuable，但這個值太大，導致co-sim無法執行。以下是我解決方式:  
>(1) FIRTester.cpp line 39: NUM_SAMPLES * sizeof(int32_t) -> NUM_SAMPLES。   
>(2) FIR.cpp line 14: (regXferLeng + (sizeof(int32_t) - 1)) / sizeof(int32_t) -> regXferLeng + ((sizeof(int32_t) - 1) / sizeof(int32_t)) 確保(1)改掉參數後，功能上還是等價 -> 待確認
>5. 跑synthesis的時候，出現warning(The report is not created yet...): rpt檔開著，需要把視窗關掉。  

觀察
1. interface接口不太一樣  
2. 使用的資源(FF、LUT等)也有些許不同 