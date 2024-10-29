pragma circom 2.1.9;

include "./aes-gcm-foldable.circom";
include "./utils.circom";

// Compute AES-GCM 
template AESGCMFOLD(INPUT_LEN) {
    assert(INPUT_LEN % 16 == 0);
    var DATA_BYTES = (INPUT_LEN * 2) + 4;
    signal input key[16];
    signal input iv[12];
    signal input aad[16];
    signal input plainText[16];

    // step_in[0..INPUT_LEN] => accumulate plaintext blocks
    // step_in[INPUT_LEN..INPUT_LEN*2]  => accumulate ciphertext blocks
    // step_in[INPUT_LEN*2..INPUT_LEN*2+4]  => lastCounter
    signal input step_in[DATA_BYTES]; 
    signal output step_out[DATA_BYTES];
    signal counter;

    // We extract the number from the 4 byte word counter
    component last_counter_bits = BytesToBits(4);
    for(var i = 0; i < 4; i ++) {
        last_counter_bits.in[i] <== step_in[INPUT_LEN*2 + i];
    }
    component last_counter_num = Bits2Num(32);
    // pass in reverse order
    for (var i = 0; i< 32; i++){
        last_counter_num.in[i] <== last_counter_bits.out[31 - i];
    }

    counter <== last_counter_num.out - 1;

    // write new plain text block.
    signal plainTextAccumulator[DATA_BYTES];    
    component writeToIndex = WriteToIndex(DATA_BYTES, 16);
    writeToIndex.array_to_write_to <== step_in;
    writeToIndex.array_to_write_at_index <== plainText;
    writeToIndex.index <== counter * 16;
    writeToIndex.out ==> plainTextAccumulator;

    // folds one block
    component aes = AESGCMFOLDABLE();
    aes.key       <== key;
    aes.iv        <== iv;
    aes.aad       <== aad;
    aes.plainText <== plainText;

    for(var i = 0; i < 4; i++) {
        aes.lastCounter[i] <== step_in[INPUT_LEN*2 + i];
    }

    // accumulate cipher text
    signal cipherTextAccumulator[DATA_BYTES];
    component writeCipherText = WriteToIndex(DATA_BYTES, 16);
    writeCipherText.array_to_write_to <== plainTextAccumulator;
    writeCipherText.array_to_write_at_index <== aes.cipherText;
    writeCipherText.index <== INPUT_LEN + counter * 16;
    writeCipherText.out ==> cipherTextAccumulator;

    // get counter
    signal counterAccumulator[DATA_BYTES];
    component writeCounter = WriteToIndex(DATA_BYTES, 4);
    writeCounter.array_to_write_to <== cipherTextAccumulator;
    writeCounter.array_to_write_at_index <== aes.counter;
    writeCounter.index <== INPUT_LEN*2;
    writeCounter.out ==> step_out;
}