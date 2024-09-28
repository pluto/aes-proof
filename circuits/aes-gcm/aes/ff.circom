// from: https://github.com/crema-labs/aes-circom/tree/main/circuits
pragma circom 2.1.9;

include "circomlib/circuits/bitify.circom";

// Finite field addition, the signal variable plus a compile-time constant
template FieldAddConst(c) {
    signal input in[8];
    // control bit, if 0, then do not perform addition
    signal input control;
    signal output out[8];

    for (var i=0; i<8; i++) {
        if(c & (1<<i) != 0) {
            // XOR operation
            out[i] <== in[i] + control - 2 * in[i] * control;
        } else {
            out[i] <== in[i];
        }
    }
}

// Finite field multiplication by 2 operation for AES. This involves left-shifting 'input' by 1 (input << 1),
// and then XORing with 0x1B if the most significate bit is 1. This is because the irreducible polynomial
// for AES's finite field (GF(2^8)) is x^8 + x^4 + x^3 + x + 1.
template FieldMul2() {
    signal input in;
    signal output out;

    signal inBits[8];
    inBits <== Num2Bits(8)(in);

    component reduce = FieldAddConst(0x1b);
    reduce.in[0] <== 0;
    for (var i = 1; i < 8; i++) {
        reduce.in[i] <== inBits[i-1];
    }
    reduce.control <== inBits[7];
    out <== Bits2Num(8)(reduce.out);
}

// Finite field multiplication by 3 operation for AES. This involves (input << 1) ⊕ input and then XORing
// with 0x1B if the most significate bit is 1.
template FieldMul3() {
    signal input in;
    signal output out;

    signal inBits[8] <== Num2Bits(8)(in);

    component reduce = FieldAddConst(0x1b);
    reduce.in[0] <== inBits[0];
    for (var i = 1; i < 8; i++) {
        reduce.in[i] <== inBits[i-1] + inBits[i] - 2 * inBits[i-1] * inBits[i];
    }
    reduce.control <== inBits[7];
    out <== Bits2Num(8)(reduce.out);
}

// Determine the parity (odd or even) of an integer that can be accommodated within 'nBits' bits.
template IsOdd(nBits) {
    signal input in;
    signal output out;
    if (nBits == 1) {
        out <== in;
    } else {
        signal bits[nBits] <== Num2Bits(nBits)(in);
        out <== bits[0];
    }
}

// Finite field multiplication.
template FieldMul() {
    signal input a;
    signal input b;
    signal inBits[2][8];
    signal output out;

    inBits[0] <== Num2Bits(8)(a);
    inBits[1] <== Num2Bits(8)(b);

    // List of finite field elements obtained by successively doubling, starting from 1.
    var power[15] = [0x1, 0x2, 0x4, 0x8, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36, 0x6c, 0xd8, 0xab, 0x4d, 0x9a];

    signal mulMatrix[8][8];
    var outLinesLc[8];
    for (var i = 0; i < 8; i++) {
        outLinesLc[i] = 0;
    }
    // Apply elementary multiplication
    for (var i = 0; i < 8; i++) {
        for (var j = 0; j < 8; j++) {
            mulMatrix[i][j] <== inBits[0][i] * inBits[1][j];
            for (var t = 0; t < 8; t++) {
                if (power[i+j] & (1 << t) != 0) {
                    outLinesLc[t] += mulMatrix[i][j];
                }
            }
        }
    }
    signal outBitsUnreduced[8];
    signal outBits[8];
    for (var i = 0; i < 8; i++) {
        outBitsUnreduced[i] <== outLinesLc[i];
        // Each element in 'outLinesLc' is incremented by a known constant number of
        // elements from 'mulMatrix', less than 31.
        outBits[i] <== IsOdd(6)(outBitsUnreduced[i]);
    }

    out <== Bits2Num(8)(outBits);
}

// Finite Field Inversion. Specially, if the input is 0, the output is also 0.
template FieldInv() {
    signal input in;
    signal output out;

    var inv[256] = [0x00, 0x01, 0x8d, 0xf6, 0xcb, 0x52, 0x7b, 0xd1, 0xe8, 0x4f, 0x29, 0xc0, 0xb0, 0xe1, 0xe5, 0xc7,
                    0x74, 0xb4, 0xaa, 0x4b, 0x99, 0x2b, 0x60, 0x5f, 0x58, 0x3f, 0xfd, 0xcc, 0xff, 0x40, 0xee, 0xb2,
                    0x3a, 0x6e, 0x5a, 0xf1, 0x55, 0x4d, 0xa8, 0xc9, 0xc1, 0x0a, 0x98, 0x15, 0x30, 0x44, 0xa2, 0xc2,
                    0x2c, 0x45, 0x92, 0x6c, 0xf3, 0x39, 0x66, 0x42, 0xf2, 0x35, 0x20, 0x6f, 0x77, 0xbb, 0x59, 0x19,
                    0x1d, 0xfe, 0x37, 0x67, 0x2d, 0x31, 0xf5, 0x69, 0xa7, 0x64, 0xab, 0x13, 0x54, 0x25, 0xe9, 0x09,
                    0xed, 0x5c, 0x05, 0xca, 0x4c, 0x24, 0x87, 0xbf, 0x18, 0x3e, 0x22, 0xf0, 0x51, 0xec, 0x61, 0x17,
                    0x16, 0x5e, 0xaf, 0xd3, 0x49, 0xa6, 0x36, 0x43, 0xf4, 0x47, 0x91, 0xdf, 0x33, 0x93, 0x21, 0x3b,
                    0x79, 0xb7, 0x97, 0x85, 0x10, 0xb5, 0xba, 0x3c, 0xb6, 0x70, 0xd0, 0x06, 0xa1, 0xfa, 0x81, 0x82,
                    0x83, 0x7e, 0x7f, 0x80, 0x96, 0x73, 0xbe, 0x56, 0x9b, 0x9e, 0x95, 0xd9, 0xf7, 0x02, 0xb9, 0xa4,
                    0xde, 0x6a, 0x32, 0x6d, 0xd8, 0x8a, 0x84, 0x72, 0x2a, 0x14, 0x9f, 0x88, 0xf9, 0xdc, 0x89, 0x9a,
                    0xfb, 0x7c, 0x2e, 0xc3, 0x8f, 0xb8, 0x65, 0x48, 0x26, 0xc8, 0x12, 0x4a, 0xce, 0xe7, 0xd2, 0x62,
                    0x0c, 0xe0, 0x1f, 0xef, 0x11, 0x75, 0x78, 0x71, 0xa5, 0x8e, 0x76, 0x3d, 0xbd, 0xbc, 0x86, 0x57,
                    0x0b, 0x28, 0x2f, 0xa3, 0xda, 0xd4, 0xe4, 0x0f, 0xa9, 0x27, 0x53, 0x04, 0x1b, 0xfc, 0xac, 0xe6,
                    0x7a, 0x07, 0xae, 0x63, 0xc5, 0xdb, 0xe2, 0xea, 0x94, 0x8b, 0xc4, 0xd5, 0x9d, 0xf8, 0x90, 0x6b,
                    0xb1, 0x0d, 0xd6, 0xeb, 0xc6, 0x0e, 0xcf, 0xad, 0x08, 0x4e, 0xd7, 0xe3, 0x5d, 0x50, 0x1e, 0xb3,
                    0x5b, 0x23, 0x38, 0x34, 0x68, 0x46, 0x03, 0x8c, 0xdd, 0x9c, 0x7d, 0xa0, 0xcd, 0x1a, 0x41, 0x1c];

    // Obtain an unchecked result from a lookup table
    out <-- inv[in];
    // Compute the product of the input and output, expected to be 1
    signal checkRes <== FieldMul()(in, out);
    // For the special case when the input is 0, both input and output should be 0
    signal isZeroIn <== IsZero()(in);
    signal isZeroOut <== IsZero()(out);
    signal checkZero <== isZeroIn * isZeroOut;
    // Ensure that either the product is 1 or both input and output are 0, satisfying at least one condition
    (1 - checkRes) * (1 - checkZero) === 0;
}

// AffineTransform required by the S-box computation.
template AffineTransform() {
    signal input inBits[8];
    signal output outBits[8];

    var matrix[8][8] = [[1, 0, 0, 0, 1, 1, 1, 1],
                        [1, 1, 0, 0, 0, 1, 1, 1],
                        [1, 1, 1, 0, 0, 0, 1, 1],
                        [1, 1, 1, 1, 0, 0, 0, 1],
                        [1, 1, 1, 1, 1, 0, 0, 0],
                        [0, 1, 1, 1, 1, 1, 0, 0],
                        [0, 0, 1, 1, 1, 1, 1, 0],
                        [0, 0, 0, 1, 1, 1, 1, 1]];
    var offset[8] = [1, 1, 0, 0, 0, 1, 1, 0];
    for (var i = 0; i < 8; i++) {
        var lc = 0;
        for (var j = 0; j < 8; j++) {
            if (matrix[i][j] == 1) {
                lc += inBits[j];
            }
        }
        lc += offset[i];
        outBits[i] <== IsOdd(3)(lc);
    }
}