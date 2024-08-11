pragma circom 2.1.9;

include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/gates.circom";
include "utils.circom";

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

// XTimes2: Multiplies by 2 in GF(2^8)
template XTimes2(){
    signal input in[8];
    signal output out[8];

    component xtimeConstant = Num2Bits(8);
    xtimeConstant.in <== 0x1b;

    component xor[7];

    component isZero = IsZero();
    isZero.in <== in[7];

    out[0] <== 1-isZero.out;
    for (var i = 0; i < 7; i++) {
        xor[i] = XOR();
        xor[i].a <== in[i];
        xor[i].b <== xtimeConstant.out[i+1] * (1-isZero.out);
        out[i+1] <== xor[i].out;
    }
}

// XTimes: Multiplies by n in GF(2^8)
// This uses a fast multiplication algorithm that uses the XTimes2 component
// Number of constaints is always constant
template XTimes(n){
    signal input in[8];
    signal output out[8];

    component bits = Num2Bits(8);
    bits.in <== n;

    component XTimes2[7];

    XTimes2[0] = XTimes2();
    XTimes2[0].in <== in;

    for (var i = 1; i < 7; i++) {
            XTimes2[i] = XTimes2();
            XTimes2[i].in <== XTimes2[i-1].out;
    }

    component xor[8];
    component mul[8];
    signal inter[8][8];

    mul[0] = MulByte();
    mul[0].a <== bits.out[0];
    mul[0].b <== in;
    inter[0] <== mul[0].c;

    for (var i = 1; i < 8; i++) {
        mul[i] = MulByte();
        mul[i].a <== bits.out[i];
        mul[i].b <== XTimes2[i-1].out;

                xor[i] = XorBits();
                xor[i].a <== inter[i-1];
                xor[i].b <== mul[i].c;
                inter[i] <== xor[i].out;
        }

    out <== inter[7];
}

