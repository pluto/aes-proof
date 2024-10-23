pragma circom 2.1.9;

include "./aes-gcm-foldable.circom";

// Compute AES-GCM 
template AESGCMFOLD(totalBytes) {
    // fix for now
    assert(totalBytes % 16 == 0);

    signal input key[16];
    signal input iv[12];
    signal input aad[16];
    signal input plainText[16];

    // Output from the last encryption step
    // Always use last bytes for inputs which are not same size.
    // step_in[0..4]  => lastCounter
    // step_in[4..20] => lastTag
    // step_in[20]    => foldedBlocks
    signal input step_in[21]; 

    // pass in number of 16 byte blocks.
    component aes = AESGCMFOLDABLE(totalBytes\16);
    aes.key       <== key;
    aes.iv        <== iv;
    aes.aad       <== aad;
    aes.plainText <== plainText;

    // Fold input last counter
    for(var i = 0; i < 4; i++) {
        aes.lastCounter[i] <== step_in[i];
    }
    // Fold input last tag
    for(var i = 0; i < 16; i++) {
        aes.lastTag[i] <== step_in[4 + i];
    }
    // Fold input folded blocks
    aes.numberOfFoldedBlocks <== step_in[20];

    // Fold Output next counter
    signal output step_out[21];
    for(var i = 0; i < 4; i++) {
        step_out[i] <== aes.counter[i];
    }
    // Fold output auth tag
    for(var i = 0; i < 16; i++) {
        step_out[4 + i] <== aes.authTag[i];
    }
    // Fold output folded blocks
    step_out[20] <== step_in[20] + 16 \ 16;

    signal output authTag[16] <== aes.authTag;
    signal output cipherText[16] <== aes.cipherText;
}