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

    var nBlocks = INPUT_LEN / 128;
    var lastBlockSize = INPUT_LEN % 128;

    component toBlocks = ToBlocks(INPUT_LEN);
    for (var i = 0; i < nBlocks * 128; i++) {
        toBlocks.stream[i] <== plainText[i];
    }

    signal tempLastBlock[lastBlockSize];
    for (var i = 0; i < lastBlockSize; i++) {
        tempLastBlock[i] <== plainText[nBlocks * 128 + i];
    }

    // intermediate signal
    signal cipherBlocks[nBlocks][4][4];
    component AddCipher[nBlocks];

    // Step 1: Generate counter blocks
    signal counterBlocks[nBlocks][128];
    component inc32[nBlocks];
    counterBlocks[1] <== initialCounterBlock;
    // For i = 2 to nBlocks, let CBi = inc32(CBi-1).
    for (var i = 2; i < nBlocks; i++) {
        inc32[i] = Increment32();
        inc32[i].in <== counterBlocks[i - 1];
        counterBlocks[i] <== inc32[i].out;
    }

    // Step 2: Encrypt each counter block with the key
    component aes[nBlocks];
    for (var i = 1; i < nBlocks -1; i++) {
        // encrypt counter block
        aes[i] = Cipher(nk);
        aes[i].key <== key;
        aes[i].block <== counterBlocks[i]; // TODO(WJ 2024-09-10): need to turn these into blocks

        // XOR cipher text with input block
        AddCipher[i] = AddCipher();    
        AddCipher[i].state <== toBlocks.blocks[i];
        AddCipher[i].cipher <== aes[i].cipher;

        // set output block
        cipherBlocks[i] <== AddCipher[i].newState;
    }

    // Step 3: Handle the last block separately
    // Y* = X* ⊕ MSBlen(X*) (CIPH_K (CB_n*))

    // encrypt the last counter block
    aes[nBlocks] = Cipher(nk);
    aes[nBlocks].key <== key;
    aes[nBlocks].block <== counterBlocks[nBlocks];

    // XOR the cipher with the last chunk of un padded plaintext
    component addLastCipher = XorMultiple(2, lastBlockSize);
    for (var i = 0; i < lastBlockSize; i++) {
        addLastCipher.inputs[0][i] <== aes[nBlocks].cipher[i];
        addLastCipher.inputs[1][i] <== tempLastBlock[i];
    }

    var bitblocks = 128 * nBlocks;
    // Convert blocks to stream
    component toStream = ToStream(nBlocks, bitblocks);
    toStream.blocks <== cipherBlocks;
    for (var i = 0; i < bitblocks; i++) {
        cipherText[i] <== toStream.stream[i];
        cipherText[bitblocks + i] <== addLastCipher.out[i];
    }
}