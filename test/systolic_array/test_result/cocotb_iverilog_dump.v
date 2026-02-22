module cocotb_iverilog_dump();
initial begin
    $dumpfile("/home/matthew/Documents/obsidian_vault/ECs/25-26/IEEE-IC-HACKATHON/ttsky-tinyTPU/test/systolic_array/test_result/systolic_array.fst");
    $dumpvars(0, systolic_array);
end
endmodule
