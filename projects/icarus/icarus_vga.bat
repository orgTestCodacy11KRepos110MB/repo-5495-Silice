..\..\bin\silice -f ..\..\frameworks\icarus_vga.v %1 -o testicarus.v
REM iverilog -pfileline=1 -Wall -Winfloop -o testicarus testicarus.v
iverilog -o testicarus testicarus.v
vvp testicarus -fst