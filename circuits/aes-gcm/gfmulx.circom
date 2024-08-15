pragma circom 2.1.9;

include "circomlib/circuits/gates.circom";

/// Multiplies a by x in GF(2^128) defined by the irreducible polynomial x^128 + x^7 + x^2 + x + 1

/// Small testing polynomial: x^8 + x^4 + x^3 + x + 1
template ghash_GFMULX() {
    var size = 128;

    signal input in[size];
    signal output out[size];
    signal temp[size];


    // Get the most significant bit of the input signal
    var msb;
    msb = in[0]; /// [>1<,0,0,0,0,0,0,0]

    // Left shift input by 1 into temp
    for (var i = 0; i < size - 1; i++) {
        temp[i] <== in[i+1];
    }
    temp[size - 1] <== 0;

    component xor1 = XOR();
    component xor2 = XOR();
    component xor3 = XOR();
    component xor4 = XOR();

    // x^128 = x^7 + x^2 + x + 1
    // XOR the input with msb * (x^7 + x^2 + x + 1)
    for (var i = 0; i < size; i++) {
        if (i == size - 1) {
            // x^0 term
            xor1.a <== temp[i];
            xor1.b <== msb;
            out[i] <== xor1.out;
        } else if (i == size - 2) {
            // x^1 term
            xor2.a <== temp[i];
            xor2.b <== msb;
            out[i] <== xor2.out;
        } else if (i == size - 3) {
            // x^2 term
            xor3.a <== temp[i];
            xor3.b <== msb;
            out[i] <== xor3.out;
        } else if (i == size - 8) {
            // x^7 term
            xor4.a <== temp[i];
            xor4.b <== msb;
            out[i] <== xor4.out;
        } 
    }   
}