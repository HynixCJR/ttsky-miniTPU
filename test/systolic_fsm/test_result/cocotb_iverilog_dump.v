module cocotb_iverilog_dump();
initial begin
    $dumpfile("/home/dphhs/projects/ttsky-miniTPU/test/systolic_fsm/test_result/systolic_array_fsm.fst");
    $dumpvars(0, systolic_array_fsm);
end
endmodule
