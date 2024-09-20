pragma circom 2.1.9;

include "utils.circom"; // xor
include "../circomlib/circuits/comparators.circom"; // isZero
include "helper_functions.circom"; // bitwise right shift
include "../circomlib/circuits/mux1.circom"; // multiplexer
include "../aes-ctr/utils.circom"; // xorbyte

// Algorithm 1: X •Y
// Input:
// blocks X, Y.
// Output:
// block X •Y.
// multiplication of two blocks in the binary extension field defined by the irreducible polynomial
// 1 + X + X^2 + X^7 + X^128
// computes a “product” block, denoted X •Y
template NistGMulByte() {

    signal input X[16];
    signal input Y[16];
    signal output out[16];

    // Let R be the bit string 11100001 || 0120. Given two blocks X and Y
    // byte 0xE1 is 11100001 in binary
    // var R[16] = [0xE1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];

    // 1. Let x0, x1...x127 denote the sequence of bits in X.
    // 2. Let Z0 = 0128 and V0 = Y.
    signal Z[129][16];
    Z[0] <== [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
    /// State accumulator. ie. V[i] is V0 holding 16 bytes
    signal V[129][16];
    V[0] <== Y;
    //       ⎧ Zi               if xi = 0;
    //  Zi+1 ⎨ 
    //       ⎩ Zi ⊕Vi           if xi =1.
    //
    // The V update is actually just gmulx (multiply binary polynomial by x)
    //
    //       ⎧ Vi >>1           if LSB1(Vi) = 0;
    //  Vi+1 ⎨ 
    //       ⎩ (Vi >>1) ⊕ R     if LSB1(Vi) =1.
    //  
    component bit[16];
    component z_i_update[128];
    component mulx[128];
    component bytesToBits = BytesToBits(16);
    bytesToBits.in <== X;
    signal bitsX[16*8];
    bitsX <== bytesToBits.out;
    for (var i = 0; i < 128; i++) {
        // log("i*8 + j", i*8 + j);
        // z_i_update
        z_i_update[i] = Z_I_UPDATE(16);
        z_i_update[i].Z <== Z[i];
        z_i_update[i].V <== V[i];
        z_i_update[i].bit_val <== bitsX[i];
        Z[i + 1] <== z_i_update[i].Z_new;

        // mulx to update V
        mulx[i] = Mulx(16);
        mulx[i].in <== V[i];
        V[i + 1] <== mulx[i].out;
    }
    // 4. Return Z128. 
    out <== Z[128];
}

// mul on 1 byte to debug by hand
template debug_1_byte() {
    signal input X[1];
    signal input Y[1];
    signal output out[1];

    signal bitsX[8];
    signal Z[9][1];
    signal V[9][1];
    Z[0] <== [0x00];
    V[0] <== Y;

    component z_i_update[8];
    component mulx[8];
    component bytesToBits = BytesToBits(1);
    bytesToBits.in <== X;   
    bitsX <== bytesToBits.out;
    for (var i = 0; i < 8; i++) {
        log("i", i);
        log("bitsX[i]", bitsX[i]);
        z_i_update[i] = Z_I_UPDATE(1);
        z_i_update[i].Z <== Z[i];
        z_i_update[i].V <== V[i];
        z_i_update[i].bit_val <== bitsX[i];
        Z[i + 1] <== z_i_update[i].Z_new;

        // mulx to update V
        mulx[i] = Mulx(1);
        mulx[i].in <== V[i];
        V[i + 1] <== mulx[i].out;
        
        log("V[i]", V[i][0]);
    }
    out <== Z[8];
}

// mul on 2 bytes to debug by hand
template debug_2_bytes() {
    signal input X[2];
    signal input Y[2];
    signal output out[2];

    signal bitsX[16];
    signal Z[17][2];
    signal V[17][2];
    Z[0] <== [0x00, 0x00];
    V[0] <== Y;

    component z_i_update[16];
    component mulx[16];
    component bytesToBits = BytesToBits(2);
    bytesToBits.in <== X;
    bitsX <== bytesToBits.out;
    for (var i = 0; i < 16; i++) {
        log("i", i);
        log("bitsX[i]", bitsX[i]);
        z_i_update[i] = Z_I_UPDATE(2);
        z_i_update[i].Z <== Z[i];
        z_i_update[i].V <== V[i];
        z_i_update[i].bit_val <== bitsX[i];
        Z[i + 1] <== z_i_update[i].Z_new;

        // mulx to update V
        mulx[i] = Mulx(2);
        mulx[i].in <== V[i];
        V[i + 1] <== mulx[i].out;
        
        log("V[i][0]", V[i][0]);
        log("V[i][1]", V[i][1]);
    }
    
    out <== Z[16];
}

// if bit value is 0, then Z_new = Z
// if bit value is 1, then Z_new = Z xor V
template Z_I_UPDATE(n_bytes) {
    signal input Z[n_bytes]; // this is Zero block in first itteration
    signal input V[n_bytes]; // this is Y in first itteration
    signal input bit_val;
    signal output Z_new[n_bytes];

    component mux = ArrayMux(n_bytes);
    mux.sel <== bit_val;
    mux.a <== Z;
    component xorBlock = XORBLOCK(n_bytes);
    xorBlock.a <== Z;
    xorBlock.b <== V;
    mux.b <== xorBlock.out;
    Z_new <== mux.out;
}

// multiplexer for arrays of length n
template ArrayMux(n) {
    signal input a[n];      // First input array
    signal input b[n];      // Second input array
    signal input sel;       // Selector signal (0 or 1)
    signal output out[n];   // Output array

    for (var i = 0; i < n; i++) {
        // If sel = 0, out[i] = a[i]
        // If sel = 1, out[i] = b[i]
        out[i] <== (b[i] - a[i]) * sel + a[i];
    }
}

// XOR 16 bytes
template XORBLOCK(n_bytes){
    signal input a[n_bytes];
    signal input b[n_bytes];
    signal output out[n_bytes];

    component xorByte[n_bytes];
    for (var i = 0; i < n_bytes; i++) {
        xorByte[i] = XorByte();
        xorByte[i].a <== a[i];
        xorByte[i].b <== b[i];
        out[i] <== xorByte[i].out;
    }
}

// right shift by one bit. If msb is 1:
// then we xor the first byte with 0xE1 (11100001: 1 + X + X^2 + X^7)
// this is the irreducible polynomial used in AES-GCM
template Mulx(n_bytes) {
    signal input in[n_bytes];
    signal output out[n_bytes];

    signal intermediate[n_bytes];

    component blockRightShift = BlockRightShift(n_bytes);
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

    for (var i = 1; i < n_bytes; i++) {
        out[i] <== intermediate[i];
    }
    out[0] <== mux.out;
}

// right shifts 16 bytes by one bit and returns the msb before the shift
template BlockRightShift(n_bytes) {
    signal input in[n_bytes];
    signal output out[n_bytes];
    signal output msb;
    
    signal shiftedbits[n_bytes*8];
    component bytesToBits = BytesToBits(n_bytes);
    for (var i = 0; i < n_bytes; i++) {
        bytesToBits.in[i] <== in[i];
    }
    msb <== bytesToBits.out[n_bytes*8 - 1];

    component BitwiseRightShift = BitwiseRightShift(n_bytes*8, 1);
    BitwiseRightShift.in <== bytesToBits.out;
    shiftedbits <== BitwiseRightShift.out;

    component bitsToBytes = BitsToBytes(n_bytes);
    bitsToBytes.in <== shiftedbits;
    out <== bitsToBytes.out;
}

// n is the number of bytes to convert to bits
template BytesToBits(n_bytes) {
    signal input in[n_bytes];
    signal output out[n_bytes*8];
    component num2bits[n_bytes];
    for (var i = 0; i < n_bytes; i++) {
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

