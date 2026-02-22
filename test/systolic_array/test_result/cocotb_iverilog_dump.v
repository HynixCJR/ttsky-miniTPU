module cocotb_iverilog_dump();
initial begin
    $dumpfile("/home/dphhs/projects/ttsky-miniTPU/test/systolic_array/test_result/systolic_array.fst");
    $dumpvars(0, systolic_array);
end
endmodule
