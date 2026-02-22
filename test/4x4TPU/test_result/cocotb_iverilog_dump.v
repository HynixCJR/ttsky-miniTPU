module cocotb_iverilog_dump();
initial begin
    $dumpfile("/home/matthew/Documents/obsidian_vault/ECs/25-26/IEEE-IC-HACKATHON/ttsky-tinyTPU/test/4x4TPU/test_result/tt_um_4x4TPU.fst");
    $dumpvars(0, tt_um_4x4TPU);
end
endmodule
