pragma circom 2.1.9;

include "./aes-gcm-foldable.circom";

// Compute AES-GCM 
template AESGCMFOLD(INPUT_LEN) {
    assert(INPUT_LEN % 16 == 0);

    var DATA_BYTES = (INPUT_LEN * 2) + 5;

    signal input key[16];
    signal input iv[12];
    signal input aad[16];
    signal input plainText[16];
    signal input cipherText[16];

    // Output from the last encryption step
    // Always use last bytes for inputs which are not same size.
    // step_in[0..INPUT_LEN] => accumulate plaintext blocks
    // step_in[INPUT_LEN..INPUT_LEN*2]  => accumulate ciphertext blocks
    // TODO(WJ 2024-10-24): Are the counter and folded blocks the same? Maybe it is redundant.
    // step_in[INPUT_LEN*2..INPUT_LEN*2+4]  => lastCounter
    // step_in[INPUT_LEN*2+5]     => foldedBlocks
    signal input step_in[DATA_BYTES]; 
    signal output step_out[DATA_BYTES];

    signal counter <== step_in[INPUT_LEN*2 + 4];




    // copy over plain text and cipher text from previous step.
    for(var i = 0; i < counter * 16; i++) {
        step_out[i] <== step_in[i];
        step_out[INPUT_LEN + i] <== step_in[INPUT_LEN + i];
    }

    // write new plain text block.
    for(var i = 0; i < 16; i++) {
        step_out[counter * 16 + i] <== plainText[i];
    }
    // write rest of plain text as zeros
    for(var i = (counter + 1) * 16; i < INPUT_LEN; i++) {
        step_out[i] <== 0;
    }

    // folds one block
    component aes = AESGCMFOLDABLE();
    aes.key       <== key;
    aes.iv        <== iv;
    aes.aad       <== aad;
    aes.plainText <== plainText;

    // Fold input last counter
    for(var i = 0; i < 4; i++) {
        aes.lastCounter[i] <== step_in[INPUT_LEN*2 + i];
    }

    // Fold input folded blocks // TODO(WJ 2024-10-24): Are the counter and folded blocks the same? Maybe it is redundant.
    aes.numberOfFoldedBlocks <== step_in[INPUT_LEN*2 + 5];

    // Fold Output next counter
    for(var i = 0; i < 4; i++) {
        step_out[INPUT_LEN*2 + i] <== aes.counter[i];
    }

    // Fold output number of folded blocks
    step_out[INPUT_LEN*2 + 5] <== step_in[INPUT_LEN*2 + 5] + 1; // increment counter for next fold

    // write new ct block
    for(var i = 0; i < 16; i++) {
        step_out[counter * 16 + INPUT_LEN + i] <== aes.cipherText[i];
    }

    // write rest of cipher text as zeros
    for(var i = (counter + 1) * 16; i < INPUT_LEN; i++) {
        step_out[i] <== 0;
    }
}

/// example: 1024 bytes