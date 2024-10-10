// from: https://github.com/crema-labs/aes-circom/tree/main/circuits
pragma circom 2.1.9;

include "sbox128.circom";
include "utils.circom";

// Key Expansion Process
//
// Original Key (Nk words)
// ┌───┬───┬───┬───┐
// │W0 │W1 │W2 │W3 │  (for AES-128, Nk=4)
// └─┬─┴─┬─┴─┬─┴─┬─┘
//   │   │   │   │
//   ▼   ▼   ▼   ▼
// ┌───────────────────────────────────────────────────────┐
// │                 Key Expansion Process                 │
// │                                                       │
// │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐      │
// │  │RotWord  │ │SubWord  │ │  XOR    │ │  XOR    │      │
// │  │         │ │         │ │ Rcon(i) │ │ W[i-Nk] │      │
// │  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘      │
// │       │           │           │           │           │
// │       └───────────┴───────────┴───────────┘           │
// │                       │                               │
// │                       ▼                               │
// │            ┌─────────────────────┐                    │
// │            │  New Expanded Key   │                    │
// │            │       Word          │                    │
// │            └─────────────────────┘                    │
// │                       │                               │
// └───────────────────────┼───────────────────────────────┘
//                         │
//                         ▼
//               Expanded Key Words
//        ┌───┬───┬───┬───┬───┬───┬───┬───┐
//        │W4 │W5 │W6 │W7 │W8 │W9 │...│W43│  (for AES-128, 44 words total)
//        └───┴───┴───┴───┴───┴───┴───┴───┘


// @param nk: number of keys which can be 4, 6, 8
// @param nr: number of rounds which can be 10, 12, 14 for AES 128, 192, 256
// @inputs key: array of nk*4 bytes representing the key
// @outputs keyExpanded: array of (nr+1)*4 words i.e for AES 128, 192, 256 it will be 44, 52, 60 words
template KeyExpansion() {
    signal input key[16];

    // var totalWords = 44;
    // var effectiveRounds = 10;

    signal output keyExpanded[44][4];

    for (var i = 0; i < 4; i++) {
        for (var j = 0; j < 4; j++) {
            keyExpanded[i][j] <== 0; //key[(4 * i) + j];
        }
    }

    component nextRound[10];

    signal nextKey[10][4][4];
    component xorWord[10][5];
    component rcon[10];
    component rotateWord[10];
    component substituteWord[10];

    for (var round = 1; round <= 10; round++) {
        // var outputWordLen = round == 10 ? 4 : nk;
        // nextRound[round - 1] = NextRound(round);


// ------------------------------------// ------------------------------------

        rotateWord[round] = Rotate(1, 4);
    for (var i = 0; i < 4; i++) {
        rotateWord.bytes[i] <== key[4 - 1][i];
    }

    substituteWord[round] = SubstituteWord();
    substituteWord[round].bytes <== rotateWord.rotated;

    rcon[round] = RCon(round);

    // component xorWord[4 + 1];
    xorWord[round][0] = XorWord();
    xorWord[round][0].bytes1 <== substituteWord[round].substituted;
    xorWord[round][0].bytes2 <== rcon[round].out;

    for (var i = 0; i < 4; i++) {
        xorWord[i+1] = XorWord();
        if (i == 0) {
            xorWord[i+1].bytes1 <== xorWord[round][0].out;
        } else {
            xorWord[i+1].bytes1 <== nextKey[i-1];
        }
        xorWord[i+1].bytes2 <== key[i];

        for (var j = 0; j < 4; j++) {
            nextKey[round][i][j] <== xorWord[i+1].out[j];
        }
    }
// ------------------------------------// ------------------------------------

        for (var i = 0; i < 4; i++) {
            for (var j = 0; j < 4; j++) {
                key[round-1][i][j] <== keyExpanded[(round * 4) + i - 4][j];
            }
        }

        for (var i = 0; i < 4; i++) {
            for (var j = 0; j < 4; j++) {
                keyExpanded[(round * 4) + i][j] <== nextKey[round-1][i][j];
            }
        }
    }
}

// @param nk: number of keys which can be 4, 6, 8
// @param o: number of output words which can be 4 or nk
template NextRound(round){
    signal input key[4][4];
    signal output nextKey[4][4];


    // for (var i = 0; i < 4; i++) {
    //     for (var j = 0; j<4; j++) {
    //         nextKey[i][j] <== 0;
    //     }
    // }

    component rotateWord = Rotate(1, 4);
    for (var i = 0; i < 4; i++) {
        rotateWord.bytes[i] <== key[4 - 1][i];
    }

    component substituteWord[2];
    substituteWord[0] = SubstituteWord();
    substituteWord[0].bytes <== rotateWord.rotated;

    component rcon = RCon(round);

    component xorWord[4 + 1];
    xorWord[0] = XorWord();
    xorWord[0].bytes1 <== substituteWord[0].substituted;
    xorWord[0].bytes2 <== rcon.out;

    for (var i = 0; i < 4; i++) {
        xorWord[i+1] = XorWord();
        if (i == 0) {
            xorWord[i+1].bytes1 <== xorWord[0].out;
        } else if(i == 4) {
            substituteWord[1] = SubstituteWord();
            substituteWord[1].bytes <== nextKey[i - 1];
            xorWord[i+1].bytes1 <== substituteWord[1].substituted;
        } else {
            xorWord[i+1].bytes1 <== nextKey[i-1];
        }
        xorWord[i+1].bytes2 <== key[i];

        for (var j = 0; j < 4; j++) {
            nextKey[i][j] <== xorWord[i+1].out[j];
        }
    }
}


