pragma circom 2.1.9;

include "./aes-gcm-foldable.circom";

template AESGCMFOLD(bytesPerFold, totalBytes) {
    // cannot fold outside chunk boundaries.
    assert(bytesPerFold % 16 == 0);
    assert(totalBytes % 16 == 0);

    signal input key[16];
    signal input iv[12];
    signal input aad[16];
    signal input plainText[bytesPerFold];

    // Output from the last encryption step
    // Always use last bytes for inputs which are not same size.
    // step_in[0] => lastCounter
    // step_in[1] => lastTag
    // step_in[2] => foldedBlocks
    signal input step_in[3][16]; 

    // For now, attempt to support variable fold size. Potential fix at 16 in the future.
    component aes = AESGCMFOLDABLE(bytesPerFold, totalBytes\16);
    aes.key <== key;
    aes.iv <== iv;
    aes.aad <== aad;
    aes.plainText <== plainText;

    // Fold inputs
    for(var i = 0; i < 4; i++) {
        var index = bytesPerFold-4+i;
        aes.lastCounter[i] <== step_in[0][index];
    }
    for(var i = 0; i < 16; i++) {
        var index = bytesPerFold-16+i;
        aes.lastTag[i] <== step_in[1][index];
    }
    // TODO: range check, assertions, stuff.
    aes.foldedBlocks <== step_in[2][bytesPerFold-1];

    // Fold Outputs
    signal output step_out[3][16];
    for(var i = 0; i < 4; i++) {
        var index = bytesPerFold-4+i;
        step_out[0][index] <== aes.counter[i];
    }
    for(var i = 0; i < 16; i++) {
        var index = bytesPerFold-16+i;
        step_out[1][index] <== aes.authTag[index];
    }
    step_out[2][bytesPerFold-1] <== step_in[2][bytesPerFold-1] + bytesPerFold \ 16;

    signal output authTag[16] <== aes.authTag;
    signal output cipherText[bytesPerFold] <== aes.cipherText;
}