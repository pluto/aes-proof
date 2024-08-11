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
template KeyExpansion(nk,nr) {
    assert(nk == 4 || nk == 6 || nk == 8 );    
    signal input key[nk * 4];
    
    var totalWords = (4 * (nr + 1));
    var effectiveRounds = nk == 4 ? 10 : totalWords\nk;

    signal output keyExpanded[totalWords][4];

    for (var i = 0; i < nk; i++) {
        for (var j = 0; j < 4; j++) {
            keyExpanded[i][j] <== key[(4 * i) + j];
        }
    }
    
    component nextRound[effectiveRounds];
    
    for (var round = 1; round <= effectiveRounds; round++) {
        var outputWordLen = round == effectiveRounds ? 4 : nk; 
        nextRound[round - 1] = NextRound(nk, outputWordLen);

        for (var i = 0; i < nk; i++) {
            for (var j = 0; j < 4; j++) {
                nextRound[round - 1].key[i][j] <== keyExpanded[(round * nk) + i - nk][j];
            }
        }

        nextRound[round - 1].round <== round;

        for (var i = 0; i < outputWordLen; i++) {
            for (var j = 0; j < 4; j++) {
                keyExpanded[(round * nk) + i][j] <== nextRound[round - 1].nextKey[i][j];
            }
        }
    }
}

// @param nk: number of keys which can be 4, 6, 8
// @param o: number of output words which can be 4 or nk
template NextRound(nk, o){
    signal input key[nk][4]; 
    signal input round;
    signal output nextKey[o][4];

    component rotateWord = Rotate(1, 4);
    for (var i = 0; i < 4; i++) {
        rotateWord.bytes[i] <== key[nk - 1][i];
    }
    
    component substituteWord[2];
    substituteWord[0] = SubstituteWord();
    substituteWord[0].bytes <== rotateWord.rotated;

    component rcon = RCon();
    rcon.round <== round; 

    component xorWord[o + 1];
    xorWord[0] = XorWord();
    xorWord[0].bytes1 <== substituteWord[0].substituted;
    xorWord[0].bytes2 <== rcon.out;

    for (var i = 0; i < o; i++) {
        xorWord[i+1] = XorWord();
        if (i == 0) {
            xorWord[i+1].bytes1 <== xorWord[0].out;
        } else if(nk == 8 && i == 4) {
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


