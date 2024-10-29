// from: https://github.com/crema-labs/aes-circom/tree/main/circuits
pragma circom 2.1.9;

include "../utils.circom";
include "sbox128.circom";


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

    var totalWords = (4 * (10 + 1));
    var effectiveRounds = 10;

    signal output keyExpanded[totalWords][4];

    for (var i = 0; i < 4; i++) {
        for (var j = 0; j < 4; j++) {
            keyExpanded[i][j] <== key[(4 * i) + j];
        }
    }

    component nextRound[effectiveRounds];
    var outputWordLen = 4;
    for (var round = 1; round <= effectiveRounds; round++) {
        nextRound[round - 1] = NextRound();
        nextRound[round - 1].round <== round;

        for (var i = 0; i < 4; i++) {
            for (var j = 0; j < 4; j++) {
                nextRound[round - 1].key[i][j] <== keyExpanded[(round * 4) + i - 4][j];
            }
        }

        for (var i = 0; i < outputWordLen; i++) {
            for (var j = 0; j < 4; j++) {
                keyExpanded[(round * 4) + i][j] <== nextRound[round - 1].nextKey[i][j];
            }
        }
    }
}

// @param nk: number of keys which can be 4, 6, 8
// @param o: number of output words which can be 4 or nk
template NextRound(){
    signal input round;
    signal input key[4][4];
    signal output nextKey[4][4];

    component rotateWord = Rotate(1, 4);
    for (var i = 0; i < 4; i++) {
        rotateWord.bytes[i] <== key[4 - 1][i];
    }

    component substituteWord[2];
    substituteWord[0] = SubstituteWord();
    substituteWord[0].bytes <== rotateWord.rotated;

    // component rcon = RCon(round);
    /// m is the number of arrarys, n is the length of each array
    component rcon = ArraySelector(10, 4);
    rcon.in <== [
        [0x01, 0x00, 0x00, 0x00],
        [0x02, 0x00, 0x00, 0x00],
        [0x04, 0x00, 0x00, 0x00],
        [0x08, 0x00, 0x00, 0x00],
        [0x10, 0x00, 0x00, 0x00],
        [0x20, 0x00, 0x00, 0x00],
        [0x40, 0x00, 0x00, 0x00],
        [0x80, 0x00, 0x00, 0x00],
        [0x1b, 0x00, 0x00, 0x00],
        [0x36, 0x00, 0x00, 0x00]
    ];
    rcon.index <== round-1;
    component xorWord[4 + 1];
    xorWord[0] = XORBLOCK(4);
    xorWord[0].a <== substituteWord[0].substituted;
    xorWord[0].b <== rcon.out;

    for (var i = 0; i < 4; i++) {
        xorWord[i+1] = XORBLOCK(4);
        if (i == 0) {
            xorWord[i+1].a <== xorWord[0].out;
        } else {
            xorWord[i+1].a <== nextKey[i-1];
        }
        xorWord[i+1].b <== key[i];

        for (var j = 0; j < 4; j++) {
            nextKey[i][j] <== xorWord[i+1].out[j];
        }
    }
}

// Outputs a round constant for a given round number
template RCon(round) {
    signal output out[4];

    assert(round > 0 && round <= 10);

    var rcon[10][4] = [
        [0x01, 0x00, 0x00, 0x00],
        [0x02, 0x00, 0x00, 0x00],
        [0x04, 0x00, 0x00, 0x00],
        [0x08, 0x00, 0x00, 0x00],
        [0x10, 0x00, 0x00, 0x00],
        [0x20, 0x00, 0x00, 0x00],
        [0x40, 0x00, 0x00, 0x00],
        [0x80, 0x00, 0x00, 0x00],
        [0x1b, 0x00, 0x00, 0x00],
        [0x36, 0x00, 0x00, 0x00]
    ];

    out <== rcon[round-1];
}

// Rotates an array of bytes to the left by a specified rotation
template Rotate(rotation, length) {
    assert(rotation < length);
    signal input bytes[length];
    signal output rotated[length];

    for(var i = 0; i < length - rotation; i++) {
        rotated[i] <== bytes[i + rotation];
    }

    for(var i = length - rotation; i < length; i++) {
        rotated[i] <== bytes[i - length + rotation];
    }
}

// Substitutes each byte in a word using the S-Box
template SubstituteWord() {
    signal input bytes[4];
    signal output substituted[4];

    component sbox[4];

    for(var i = 0; i < 4; i++) {
        sbox[i] = SBox128();
        sbox[i].in <== bytes[i];
        substituted[i] <== sbox[i].out;
    }
}