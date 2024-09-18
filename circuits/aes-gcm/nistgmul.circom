pragma circom 2.1.9;

include "utils.circom"; // xor
include "circomlib/circuits/comparators.circom"; // isZero
include "helper_functions.circom"; // bitwise right shift
include "circomlib/circuits/mux1.circom"; // multiplexer
include "../aes-ctr/utils.circom"; // xorbyte

// Algorithm 1: X •Y
// Input:
// blocks X, Y.
// Output:
// block X •Y.
// multiplication of two blocks in the binary extension field defined by the irreducible polynomial
// 1 + X + X^2 + X^7 + X^128
// computes a “product” block, denoted X •Y:

template NistGMulBit() {

    signal input X[128];
    signal input Y[128];
    signal output out[128];

    // Let R be the bit string 11100001 || 0120. Given two blocks X and Y
    var R[128] = [
        1, 1, 1, 0, 0, 0, 0, 1, // 8
        0, 0, 0, 0, 0, 0, 0, 0, // 16
        0, 0, 0, 0, 0, 0, 0, 0, // 24
        0, 0, 0, 0, 0, 0, 0, 0, // 32
        0, 0, 0, 0, 0, 0, 0, 0, // 40
        0, 0, 0, 0, 0, 0, 0, 0, // 48
        0, 0, 0, 0, 0, 0, 0, 0, // 56
        0, 0, 0, 0, 0, 0, 0, 0, // 64
        0, 0, 0, 0, 0, 0, 0, 0, // 72
        0, 0, 0, 0, 0, 0, 0, 0, // 80
        0, 0, 0, 0, 0, 0, 0, 0, // 88
        0, 0, 0, 0, 0, 0, 0, 0, // 96
        0, 0, 0, 0, 0, 0, 0, 0, // 104
        0, 0, 0, 0, 0, 0, 0, 0, // 112
        0, 0, 0, 0, 0, 0, 0, 0, // 120
        0, 0, 0, 0, 0, 0, 0, 0
    ];

    // 1. Let x0, x1...x127 denote the sequence of bits in X.
    // 2. Let Z0 = 0128 and V0 = Y.
    signal Z[128];
    Z[0] <== 0;
    /// State accumulator
    signal V[128][128];
    V[0] <== Y;

    //
    // 3. For i = 0 to 127, calculate blocks Zi+1 and Vi+1 as follows:
    //
    //       ⎧ Zi               if xi = 0;
    //  Zi+1 ⎨ 
    //       ⎩ Zi ⊕Vi           if xi = 1.
    //
    //       ⎧ Vi >>1           if LSB1(Vi) = 0; // example 01101010 >> 1 = 00110101 right shift
    //  Vi+1 ⎨                                   // lsb1(001) = 1 (rightmost bit is 1)
    //       ⎩ (Vi >>1) ⊕ R     if LSB1(Vi) = 1. 
    //  
    component XorBit[128];
    component XorArr[128];
    component IsZero[128];
    component Zmux[128];
    component Vmux[128];
    component BitwiseRightShift[128];
    for (var i = 0; i < 127; i++) {
        IsZero[i] = IsZero();
        IsZero[i].in <== X[i];
        Zmux[i] = Mux1();
        Zmux[i].s <== IsZero[i].out; // selector if 0, if yes return 1, else return zero

        Zmux[i].c[1] <== Z[i]; // selector 1
        // if (IsZero[i].out == 0) {
        //     Z[i +1] <== Z[i];
        // } else {
        XorBit[i] = XOR();
        XorBit[i].a <== Z[i];
        XorBit[i].b <== V[i][i];
        Zmux[i].c[0] <==XorBit[i].out; // if selector is 0
        // }
        Z[i+1] <== Zmux[i].out;

        BitwiseRightShift[i] = BitwiseRightShift(128, 1);
        BitwiseRightShift[i].in <== V[i];

        Vmux[i] = ArrayMux(128);
        Vmux[i].sel <== V[i][127]; // selector is LSB
        Vmux[i].a <== BitwiseRightShift[i].out; // if selector is 0

        XorArr[i] = BitwiseXor(128);
        XorArr[i].a <== BitwiseRightShift[i].out;
        XorArr[i].b <== R;
        Vmux[i].b <== XorArr[i].out; // if selector is 1
        V[i+1] <== Vmux[i].out;

    }
    // 4. Return Z128. 
    out <== Z;
}

template ArrayMux(n) {
    signal input a[n];      // First input array
    signal input b[n];      // Second input array
    signal input sel;       // Selector signal (0 or 1)
    signal output out[n];   // Output array

    for (var i = 0; i < n; i++) {
        // If sel = 0, out[i] = b[i]
        // If sel = 1, out[i] = a[i]
        out[i] <== (a[i] - b[i]) * sel + b[i];
    }
}

template NistGMulByte() {

    signal input X[16];
    signal input Y[16];
    signal output out[16];

    // Let R be the bit string 11100001 || 0120. Given two blocks X and Y
    // byte 0xE1 is 11100001 in binary
    // var R[16] = [0xE1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];

    // 1. Let x0, x1...x127 denote the sequence of bits in X.
    // 2. Let Z0 = 0128 and V0 = Y.
    signal Z[16][16];
    Z[0] <== [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
    /// State accumulator. ie. V[i] is V0 holding 16 bytes
    signal V[16][16];
    V[0] <== Y;

    // 3. For i = 0 to 127, calculate blocks Zi+1 and Vi+1 as follows:
    //
    //       ⎧ Zi               if xi = 0;
    //  Zi+1 ⎨ 
    //       ⎩ Zi ⊕Vi           if xi =1.
    //
    //       ⎧ Vi >>1           if LSB1(Vi) = 0;
    //  Vi+1 ⎨ 
    //       ⎩ (Vi >>1) ⊕ R     if LSB1(Vi) =1.
    //  
    component bit[16] = Num2Bits(8);
    for (var i = 0; i < 16; i++) {

        // call z_i_update
        // do the mulx for v
    }
    // 4. Return Z128. 

}

// TODO: Write a test for this
template z_i_update(bit_val) {
    signal input Z[16];
    signal input V[16];
    signal output Z_new[16];

    component mulx = Mulx();
    mulx.s <== bit_val;
    mulx.c[0] <== Z;
    component xorBlock = XORBLOCK();
    xorBlock.a <== Z;
    xorBlock.b <== V;
    mulx.c[1] <== xorBlock.out;
    Z_new <== mulx.out;
}

// TODO: Write a test for this
template XORBLOCK(){
    signal input a[16];
    signal input b[16];
    signal output out[16];

    component xorByte[16];
    for (var i = 0; i < 16; i++) {
        xorByte[i] = XorByte();
        xorByte[i].a <== a[i];
        xorByte[i].b <== b[i];
        out[i] <== xorByte[i].out;
    }
}

// right shift by one bit. If msb is 1:
// then we xor the first byte with 0xE1 (11100001: 1 + X + X^2 + X^7)
// this is the irreducible polynomial used in AES-GCM
template Mulx() {
    signal input in[16];
    signal output out[16];

    signal intermediate[16];

    component blockRightShift = BlockRightShift();
    blockRightShift.in <== in;
    intermediate <== blockRightShift.out;

    component xorByte = XorByte();
    xorByte.a <== intermediate[0];
    xorByte.b <== 0xE1; // 11100001

    // if msb is 1, then we xor the first byte with R[0]
    component mux = Mux1();
    mux.s <== blockRightShift.msb;
    mux.c[0] <== intermediate[0];
    mux.c[1] <== xorByte.out;

    for (var i = 1; i < 16; i++) {
        out[i] <== intermediate[i];
    }
    out[0] <== mux.out;
}

// right shifts 16 bytes by one bit and returns the msb before the shift
template BlockRightShift() {
    signal input in[16];
    signal output out[16];
    signal output msb;
    
    signal shiftedbits[128];
    component bytesToBits = BytesToBits(16);
    for (var i = 0; i < 16; i++) {
        bytesToBits.in[i] <== in[i];
    }
    msb <== bytesToBits.out[127];

    component BitwiseRightShift = BitwiseRightShift(128, 1);
    BitwiseRightShift.in <== bytesToBits.out;
    shiftedbits <== BitwiseRightShift.out;

    component bitsToBytes = BitsToBytes(16);
    bitsToBytes.in <== shiftedbits;
    out <== bitsToBytes.out;
}

// n is the number of bytes to convert to bits
template BytesToBits(n) {
    signal input in[n];
    signal output out[n*8];
    component num2bits[n];
    for (var i = 0; i < n; i++) {
        num2bits[i] = Num2Bits(8);
        num2bits[i].in <== in[i];
        for (var j = 7; j >=0; j--) {
            out[i*8 + j] <== num2bits[i].out[7 -j];
        }
    }
}

// n is the number of bytes we want
template BitsToBytes(n) {
    signal input in[n*8];
    signal output out[n];
    component bits2num[n];
    for (var i = 0; i < n; i++) {
        bits2num[i] = Bits2Num(8);
        for (var j = 0; j < 8; j++) {
            bits2num[i].in[7 - j] <== in[i*8 + j];
        }
        out[i] <== bits2num[i].out;
    }
}

