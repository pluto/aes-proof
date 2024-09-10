pragma circom 2.1.9;
include "../aes-ctr/cipher.circom";
include "helper_functions.circom";
include "../aes-ctr/ctr.circom";

// GCTR Process to be used in AES-GCM
//
//            ┌───────────┐           inc           ┌───────────┐
//            │    ICB    │ ──────────────────────▶ │    CB2    │
//            └───────────┘                         └───────────┘
//                  │                                      │
//                  ▼                                      ▼
//            ┌──────────┐                           ┌──────────┐
//            │  CIPH_K  │                           │  CIPH_K  │
//            └──────────┘                           └──────────┘
//                  │                                      │
//                  ▼                                      ▼
//             ┌──────────┐                           ┌──────────┐
//             │    X1    │                           │     X2   │
//             └──────────┘                           └──────────┘
//                   │                                      │
//   ┌───────┐       ▼                       ┌───────┐      ▼
//   |  X_1  |───▶  XOR                      |  X_2  |───▶ XOR
//   └───────┘       │                       └───────┘      │
//                   ▼                                      ▼
//               ┌──────┐                                ┌──────┐
//               │  Y1  │                                │  Y2  │
//               └──────┘                                └──────┘
//                   │                                       │
//                   ▼                                       ▼
//
// GCTR_K (ICB, X1 || X2 || ... || X_n*) = Y1 || Y2 || ... || Y_n*.


template GCTR(INPUT_LEN, nk) {
    signal input key[nk * 4];
    signal input initialCounterBlock[128];
    signal input plainText[INPUT_LEN];
    signal output cipherText[INPUT_LEN];

    // number of 128 bit blocks in the plaintext
    var nBlocks = INPUT_LEN / 128;
    // size of the last block
    var lastBlockSize = INPUT_LEN % 128;
    // total number of bits in the plaintext blocks
    var bitblocks = 128 * nBlocks;

    // last block of plaintext
    signal tempLastBlock[lastBlockSize];
    for (var i = 0; i < lastBlockSize -1; i++) {
        tempLastBlock[i] <== plainText[nBlocks * 128 + i];
    }

    // generate plaintext blocks
    // note to not use the last block of plaintext
    component plainTextBlocks = ToBlocks(INPUT_LEN);
    plainTextBlocks.stream <== plainText;


    // Step 1: Generate counter blocks
    // signal incCounterBlocks[nBlocks][128];
    component counterBlocks[nBlocks];
    counterBlocks[1] <== ToBlocks(128);
    counterBlocks[1].stream <== initialCounterBlock;

    component inc32[nBlocks];
    // For i = 2 to nBlocks, let CBi = inc32(CBi-1).
    for (var i = 2; i < nBlocks; i++) {
        inc32[i] = Increment32();
        inc32[i].in <== incCounterBlocks[i - 1];
        incCounterBlocks[i] <== inc32[i].out;
    }

    // Convert blocks to stream
    component toStream = ToStream(nBlocks, bitblocks);
    // Step 2: Encrypt each counter block with the key
    component aes[nBlocks];
    component AddCipher[nBlocks];
    for (var i = 1; i < nBlocks -1; i++) {
        // convert counter block to blocks type
        counterBlocks[i] = ToBlocks(128);
        counterBlocks[i].stream <== incCounterBlocks[i];

        // encrypt counter block
        aes[i] = Cipher(nk);
        aes[i].key <== key;
        aes[i].block <== counterBlocks[i].blocks[0];

        // XOR cipher text with input block
        AddCipher[i] = AddCipher();    
        AddCipher[i].state <== plainTextBlocks.blocks[i];
        AddCipher[i].cipher <== aes[i].cipher;

        // set output block
        toStream.blocks[i] <== AddCipher[i].newState;
    }

    // Step 3: Handle the last block separately
    // Y* = X* ⊕ MSBlen(X*) (CIPH_K (CB_n*))
    // convert last counter block to blocks
    counterBlocks[nBlocks] = ToBlocks(128);
    counterBlocks[nBlocks].stream <== incCounterBlocks[nBlocks];

    // encrypt the last counter block
    aes[nBlocks] = Cipher(nk);
    aes[nBlocks].key <== key;
    aes[nBlocks].block <== counterBlocks[nBlocks].blocks[0];

    // XOR the cipher with the last chunk of un padded plaintext
    component aesCipherToStream = ToStream(1, 128);
    component addLastCipher = XorMultiple(2, lastBlockSize);
    for (var i = 0; i < lastBlockSize; i++) {
        // convert cipher to stream
        aesCipherToStream.blocks[0] <== aes[nBlocks].cipher;
        addLastCipher.inputs[0][i] <== aesCipherToStream.stream[i];
        addLastCipher.inputs[1][i] <== tempLastBlock[i];
    }


    for (var i = 0; i < bitblocks; i++) {
        cipherText[i] <== toStream.stream[i];
        cipherText[bitblocks + i] <== addLastCipher.out[i];
    }
}