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
    // step_in[0..4]  => lastCounter
    // step_in[4..20] => lastTag
    // step_in[20]    => foldedBlocks
    signal input step_in[21]; 

    // For now, attempt to support variable fold size. Potential fix at 16 in the future.
    component aes = AESGCMFOLDABLE(bytesPerFold, totalBytes\16);
    aes.key       <== key;
    aes.iv        <== iv;
    aes.aad       <== aad;
    aes.plainText <== plainText;

    // Fold inputs
    for(var i = 0; i < 4; i++) {
        aes.lastCounter[i] <== step_in[i];
    }
    for(var i = 0; i < 16; i++) {
        aes.lastTag[i] <== step_in[4 + i];
    }
    // TODO: range check, assertions, stuff.
    aes.foldedBlocks <== step_in[20];

    // Fold Outputs
    signal output step_out[21];
    for(var i = 0; i < 4; i++) {
        step_out[i] <== aes.counter[i];
    }
    for(var i = 0; i < 16; i++) {
        step_out[4 + i] <== aes.authTag[i];
    }
    step_out[20] <== step_in[20] + bytesPerFold \ 16;
}

component main { public [step_in] } = AESGCMFOLD(16, 32);