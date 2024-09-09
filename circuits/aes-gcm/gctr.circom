pragma circom 2.1.9;
include "aes-ctr/cipher.circom";
include "helper_functions.circom";
include "aes-ctr/ctr.circom";

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
    if (INPUT_LEN % 128 > 0) {
        nBlocks = nBlocks + 1;
    }

    component toBlocks = ToBlocks(INPUT_LEN);
    toBlocks.stream <== plainText;

    // intermediate signal
    signal cipherBlocks[nBlocks][4][4];
    component AddCipher[nBlocks];

    // Step 1: Generate counter blocks
    signal counterBlocks[nBlocks][128];
    component inc32[nBlocks];
    counterBlocks[0] <== initialCounterBlock;
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
        aes[i].block <== counterBlocks.counterBlocks[i];

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

    // XOR the MSB(CIPH) with the last block of plaintext

    // notes: the to blocks template will automatically pad the last block with 1s if necessary
    // this is not what we want in the algorithm, so i need to store the last bits before toBlocks
    // then i can use them here.

    addLastCipher.state <== toBlocks.blocks[nBlocks];
    addLastCipher.cipher <== aes[nBlocks].cipher;


    // Convert blocks to stream
    component toStream = ToStream(nBlocks, INPUT_LEN);
    toStream.blocks <== cipherBlocks;

    cipherText <== toStream.stream;
}