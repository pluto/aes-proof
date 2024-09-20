pragma circom 2.1.9;

include "key_expansion.circom";
include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/gates.circom";
include "transformations.circom";
include "mix_columns.circom";

// Cipher Process
// nk: number of keys which can be 4, 6, 8
// AES 128, 192, 256 have 10, 12, 14 rounds.
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

// @param nk: number of keys which can be 4, 6, 8
// @inputs block: 4x4 matrix representing the input block
// @inputs key: array of nk*4 bytes representing the key
// @outputs cipher: 4x4 matrix representing the output block
template Cipher(nk){
        assert(nk == 4 || nk == 6 || nk == 8 );
        signal input block[4][4];
        signal input key[nk * 4];
        signal output cipher[4][4];

        var nr = Rounds(nk);
        
        component keyExpansion = KeyExpansion(nk,nr);
        keyExpansion.key <== key;

        component addRoundKey[nr+1]; 
        component subBytes[nr];
        component shiftRows[nr];
        component mixColumns[nr-1];

        signal interBlock[nr][4][4];

        addRoundKey[0] = AddRoundKey();
        addRoundKey[0].state <== block;
        for (var i = 0; i < 4; i++) {
                addRoundKey[0].roundKey[i] <== keyExpansion.keyExpanded[i];
        }

        interBlock[0] <== addRoundKey[0].newState;
        for (var i = 1; i < nr; i++) {
                subBytes[i-1] = SubBlock();
                subBytes[i-1].state <== interBlock[i-1];

                shiftRows[i-1] = ShiftRows();
                shiftRows[i-1].state <== subBytes[i-1].newState;

                mixColumns[i-1] = MixColumns();
                mixColumns[i-1].state <== shiftRows[i-1].newState;

                addRoundKey[i] = AddRoundKey();
                addRoundKey[i].state <== mixColumns[i-1].out;
                 for (var j = 0; j < 4; j++) {
                        addRoundKey[i].roundKey[j] <== keyExpansion.keyExpanded[j + (i * 4)];
                }

                interBlock[i] <== addRoundKey[i].newState;
        }

        subBytes[nr-1] = SubBlock();
        subBytes[nr-1].state <== interBlock[nr-1];

        shiftRows[nr-1] = ShiftRows();
        shiftRows[nr-1].state <== subBytes[nr-1].newState;

        addRoundKey[nr] = AddRoundKey();
        addRoundKey[nr].state <== shiftRows[nr-1].newState;
        for (var i = 0; i < 4; i++) {
                addRoundKey[nr].roundKey[i] <== keyExpansion.keyExpanded[i + (nr * 4)];
        }

        cipher <== addRoundKey[nr].newState;
}

// @param nk: number of keys which can be 4, 6, 8
// @returns number of rounds
// AES 128, 192, 256 have 10, 12, 14 rounds.
function Rounds (nk) {
    if (nk == 4) {
       return 10;
    } else if (nk == 6) {
        return 12;
    } else {
        return 14;
    }
}


//convert stream of plain text to blocks of 16 bytes
template ToBlocks(l){
        signal input stream[l];

        var n = l\16;
        if(l%16 > 0){
                n = n + 1;
        }
        signal output blocks[n][4][4];

        var i, j, k;

        for (var idx = 0; idx < l; idx++) {
                blocks[i][k][j] <== stream[idx];
                k = k + 1;
                if (k == 4){
                        k = 0;
                        j = j + 1;
                        if (j == 4){
                                j = 0;
                                i = i + 1;
                        }
                }
        }

        if (l%16 > 0){
               blocks[i][k][j] <== 1;
               k = k + 1;
        }
}

// convert blocks of 16 bytes to stream of bytes
template ToStream(n,l){
        signal input blocks[n][4][4];

        signal output stream[l];

        var i, j, k;

        while(i*16 + j*4 + k < l){
                stream[i*16 + j*4 + k] <== blocks[i][k][j];
                k = k + 1;
                if (k == 4){
                        k = 0;
                        j = j + 1;
                        if (j == 4){
                                j = 0;
                                i = i + 1;
                        }
                }
        }
}

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

// converts iv to counter blocks
// iv is 16 bytes
template GenerateCounterBlocks(n){
        assert(n < 0xffffffff);
        signal input iv[16];
        signal output counterBlocks[n][4][4];

        var ivr[16] = iv;

        component toBlocks[n];

        for (var i = 0; i < n; i++) {
                toBlocks[i] = ToBlocks(16);
                toBlocks[i].stream <-- ivr;
                counterBlocks[i] <== toBlocks[i].blocks[0];
                ivr[15] = (ivr[15] + 1)%256;
                if (ivr[15] == 0){
                        ivr[14] = (ivr[14] + 1)%256;
                        if (ivr[14] == 0){
                                ivr[13] = (ivr[13] + 1)%256;
                                if (ivr[13] == 0){
                                        ivr[12] = (ivr[12] + 1)%256;
                                }
                        }
                }

        }
}