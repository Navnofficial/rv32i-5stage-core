iverilog -g2012 -o sim/pipeline_Counter.vvp \
  rtl/core/PC.v rtl/core/PC_Adder.v rtl/core/Mux.v \
  rtl/core/ALU.v rtl/core/ALU_Decoder.v rtl/core/Main_Decoder.v \
  rtl/core/Control_Unit_Top.v rtl/core/Branch_Comparator.v \
  rtl/core/Register_File.v rtl/core/Sign_Extend.v \
  rtl/core/Instruction_Memory.v rtl/core/Data_Memory.v \
  rtl/core/Fetch_Cycle.v rtl/core/Decode_Cycle.v \
  rtl/core/Execute_Cycle.v rtl/core/Memory_Cycle.v \
  rtl/core/Write_Back_Cycle.v rtl/core/Hazard_unit.v \
  rtl/top/Pipeline_Top.v tb/core/Pipeline_Top_tb.v \
&& vvp sim/pipeline.vvp