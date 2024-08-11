pragma circom 2.1.9;

include "sbox128.circom";
include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/gates.circom";

// Converts an array of bytes to an array of words
template BytesToWords(n) {
    assert(n % 4 == 0);
    signal input bytes[n];
    signal output words[n \ 4][n];

    for (var i = 0; i < n \ 4; i++) {
        for(var j = 0; j < 4; j++) {
            words[i][j] <== bytes[i * 4 + j];
        }
    }
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

// Outputs a round constant for a given round number
template RCon() {
    signal input round;
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

    out <-- rcon[round-1];
}


// XORs two words (arrays of 4 bytes each)
template XorWord() {
    signal input bytes1[4];
    signal input bytes2[4];
    
    component n2b[4 * 2];
    component b2n[4];
    component xor[4][8];

    signal output out[4];

    for(var i = 0; i < 4; i++) {
        n2b[2 * i] = Num2Bits(8);
        n2b[2 * i + 1] = Num2Bits(8);
        n2b[2 * i].in <== bytes1[i];
        n2b[2 * i + 1].in <== bytes2[i];
        b2n[i] = Bits2Num(8);

        for (var j = 0; j < 8; j++) {
            xor[i][j] = XOR();
            xor[i][j].a <== n2b[2 * i].out[j];
            xor[i][j].b <== n2b[2 * i + 1].out[j];
            b2n[i].in[j] <== xor[i][j].out;
        }

        out[i] <== b2n[i].out;
    }
}

// Selects between two words based on a condition
template WordSelector() {
    signal input condition;
    signal input bytes1[4];
    signal input bytes2[4];
    signal output out[4];

    for (var i = 0; i < 4; i++) {
        out[i] <== condition * (bytes1[i] - bytes2[i]) + bytes2[i];
    }
}

// Multiplies a byte by an array of bits
template MulByte(){
    signal input a;
    signal input b[8];
    signal output c[8];

    for (var i = 0; i < 8; i++) {
        c[i] <== a * b[i];
    }
}

// XORs two bytes
template XorByte(){
        signal input a;
        signal input b;
        signal output out;

        component abits = Num2Bits(8);
        abits.in <== a;

        component bbits = Num2Bits(8);
        bbits.in <== b;

        component XorBits = XorBits();
        XorBits.a <== abits.out;
        XorBits.b <== bbits.out;

        component num = Bits2Num(8);
        num.in <== XorBits.out;

        out <== num.out;
}

// XORs two arrays of bits
template XorBits(){
        signal input a[8];
        signal input b[8];
        signal output out[8];

    component xor[8];
    for (var i = 0; i < 8; i++) {
        xor[i] = XOR();
        xor[i].a <== a[i];
        xor[i].b <== b[i];
        out[i] <== xor[i].out;
    }
}