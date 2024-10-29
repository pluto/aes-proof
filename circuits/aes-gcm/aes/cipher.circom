// from: https://github.com/crema-labs/aes-circom/tree/main/circuits
pragma circom 2.1.9;

include "key_expansion.circom";
include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/gates.circom";
include "mix_columns.circom";

// Cipher Process
// AES 128 keys have 10 rounds.
// Input Block   Initial Round Key          Round Key             Final Round Key
//     │                │                       │                       │
//     ▼                ▼                       ▼                       ▼
//  ┌─────────┐    ┌──────────┐ ┌────────┐ ┌──────────┐ ┌────────┐ ┌──────────┐
//  │ Block   │──► │   Add    │ │  Sub   │ │   Mix    │ │  Sub   │ │   Add    │
//  │         │    │  Round   │ │ Bytes  │ │ Columns  │ │ Bytes  │ │  Round   │
//  │         │    │   Key    │ │        │ │          │ │        │ │   Key    │
//  └─────────┘    └────┬─────┘ └───┬────┘ └────┬─────┘ └───┬────┘ └────┬─────┘
//                      │           │           │           │           │
//                      ▼           ▼           ▼           ▼           ▼
//                 ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
//                 │ Round 0 │ │ Round 1 │ │ Round 2 │ │ Round   │ │  Final  │
//                 │         │ │   to    │ │   to    │ │ Nr - 1  │ │  Round  │
//                 │         │ │ Nr - 2  │ │ Nr - 1  │ │         │ │         │
//                 └─────────┘ └─────────┘ └─────────┘ └─────────┘ └────┬────┘
//                                                                      │
//                                                                      ▼
//                                                                 Ciphertext


// @inputs block: 4x4 matrix representing the input block
// @inputs key: array of 16 bytes representing the key
// @outputs cipher: 4x4 matrix representing the output block
template Cipher(){
        signal input block[4][4];
        signal input key[16];
        signal output cipher[4][4];
        
        component keyExpansion = KeyExpansion();
        keyExpansion.key <== key;

        component addRoundKey[11]; 
        component subBytes[10];
        component shiftRows[10];
        component mixColumns[9];

        signal interBlock[10][4][4];

        addRoundKey[0] = AddRoundKey();
        addRoundKey[0].state <== block;
        for (var i = 0; i < 4; i++) {
                addRoundKey[0].roundKey[i] <== keyExpansion.keyExpanded[i];
        }

        interBlock[0] <== addRoundKey[0].newState;
        // for each round. 
        for (var i = 1; i < 10; i++) {
                // SubBytes
                subBytes[i-1] = SubBlock();
                subBytes[i-1].state <== interBlock[i-1];

                // ShiftRows
                shiftRows[i-1] = ShiftRows();
                shiftRows[i-1].state <== subBytes[i-1].newState;

                // MixColumns
                mixColumns[i-1] = MixColumns();
                mixColumns[i-1].state <== shiftRows[i-1].newState;

                // AddRoundKey
                addRoundKey[i] = AddRoundKey();
                addRoundKey[i].state <== mixColumns[i-1].out;
                 for (var j = 0; j < 4; j++) {
                        addRoundKey[i].roundKey[j] <== keyExpansion.keyExpanded[j + (i * 4)];
                }

                interBlock[i] <== addRoundKey[i].newState;
        }

        // Final SubBytes
        subBytes[9] = SubBlock();
        subBytes[9].state <== interBlock[9];

        shiftRows[9] = ShiftRows();
        shiftRows[9].state <== subBytes[9].newState;

        // Final AddRoundKey
        addRoundKey[10] = AddRoundKey();
        addRoundKey[10].state <== shiftRows[9].newState;
        for (var i = 0; i < 4; i++) {
                addRoundKey[10].roundKey[i] <== keyExpansion.keyExpanded[i + (40)];
        }

        cipher <== addRoundKey[10].newState;
}

// XORs a cipher state: 4x4 byte array
template AddCipher(){
    signal input state[4][4];
    signal input cipher[4][4];
    signal output newState[4][4];

    component xorbyte[4][4];

    for (var i = 0; i < 4; i++) {
        for (var j = 0; j < 4; j++) {
            xorbyte[i][j] = XorByte();
            xorbyte[i][j].a <== state[i][j];
            xorbyte[i][j].b <== cipher[i][j];
            newState[i][j] <== xorbyte[i][j].out;
        }
    }
}

// ShiftRows: Performs circular left shift on each row
// 0, 1, 2, 3 shifts for rows 0, 1, 2, 3 respectively
template ShiftRows(){
    signal input state[4][4];
    signal output newState[4][4];

    component shiftWord[4];

    for (var i = 0; i < 4; i++) {
        // Rotate: Performs circular left shift on each row
        shiftWord[i] = Rotate(i, 4);
        shiftWord[i].bytes <== state[i];
        newState[i] <== shiftWord[i].rotated;
    }
}

 // Applies S-box substitution to each byte
template SubBlock(){
        signal input state[4][4];
        signal output newState[4][4];
        component sbox[4];

        for (var i = 0; i < 4; i++) {
                sbox[i] = SubstituteWord();
                sbox[i].bytes <== state[i];
                newState[i] <== sbox[i].substituted;
        }
}

// AddRoundKey: XORs the state with transposed the round key
template AddRoundKey(){
    signal input state[4][4];
    signal input roundKey[4][4];
    signal output newState[4][4];

    component xorbyte[4][4];

    for (var i = 0; i < 4; i++) {
        for (var j = 0; j < 4; j++) {
            xorbyte[i][j] = XorByte();
            xorbyte[i][j].a <== state[i][j];
            xorbyte[i][j].b <== roundKey[j][i];
            newState[i][j] <== xorbyte[i][j].out;
        }
    }
}