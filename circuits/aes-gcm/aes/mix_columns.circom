pragma circom 2.1.9;

include "transformations.circom";
include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/gates.circom";
include "tbox.circom";

// MixColumns: Applies the equation for each column:
// [s'0,c]   [2 3 1 1][s0,c]
// [s'1,c] = [1 2 3 1][s1,c]
// [s'2,c]   [1 1 2 3][s2,c]
// [s'3,c]   [3 1 1 2][s3,c]
// Where c is the column number, s are input bytes, s' are output bytes
template MixColumns(){
    signal input state[4][4];
    signal output out[4][4];

    component s0[4];
    component s1[4];
    component s2[4];
    component s3[4];

    for (var i = 0; i < 4; i++) {
        s0[i] = S0();
        s1[i] = S1();
        s2[i] = S2();
        s3[i] = S3();

        for(var j = 0; j < 4; j++) {
            s0[i].in[j] <== state[j][i];
            s1[i].in[j] <== state[j][i];
            s2[i].in[j] <== state[j][i];
            s3[i].in[j] <== state[j][i];
        }

        out[0][i] <== s0[i].out;
        out[1][i] <== s1[i].out;
        out[2][i] <== s2[i].out;
        out[3][i] <== s3[i].out;
    }
}

// S0: Implements the equation
// out = (2 • in[0]) ⊕ (3 • in[1]) ⊕ in[2] ⊕ in[3]
template S0(){
    signal input in[4];
    signal output out;
    component num2bits[4];
    component xor[3];

    for (var i = 2; i < 4; i++) {
        num2bits[i] = Num2Bits(8);
        num2bits[i].in <== in[i];
    }

    num2bits[0] = Num2Bits(8);
    num2bits[0].in <-- TBox(0, in[0]);

    num2bits[1] = Num2Bits(8);
    num2bits[1].in <-- TBox(1, in[1]);

    xor[0] = XorBits();
    xor[0].a <== num2bits[0].out;
    xor[0].b <== num2bits[1].out;

    xor[1] = XorBits();
    xor[1].a <== xor[0].out;
    xor[1].b <== num2bits[2].out;

    xor[2] = XorBits();
    xor[2].a <== xor[1].out;
    xor[2].b <== num2bits[3].out;

    component b2n = Bits2Num(8);
    for (var i = 0; i < 8; i++) {
        b2n.in[i] <== xor[2].out[i];
    }

    out <== b2n.out;
}

// S1: Implements the equation
// out = in[0] ⊕ (2 • in[1]) ⊕ (3 • in[2]) ⊕ in[3]
template S1(){
    signal input in[4];
    signal output out;
    component num2bits[4];
    component xor[3];

    num2bits[0] = Num2Bits(8);
    num2bits[0].in <== in[0];

    num2bits[1] = Num2Bits(8);
    num2bits[1].in <-- TBox(0, in[1]);

    num2bits[2] = Num2Bits(8);
    num2bits[2].in <-- TBox(1, in[2]);

    num2bits[3] = Num2Bits(8);
    num2bits[3].in <== in[3];

    xor[0] = XorBits();
    xor[0].a <== num2bits[0].out;
    xor[0].b <== num2bits[1].out;

    xor[1] = XorBits();
    xor[1].a <== xor[0].out;
    xor[1].b <== num2bits[2].out;

    xor[2] = XorBits();
    xor[2].a <== xor[1].out;
    xor[2].b <== num2bits[3].out;

    component b2n = Bits2Num(8);
    for (var i = 0; i < 8; i++) {
        b2n.in[i] <== xor[2].out[i];
    }

    out <== b2n.out;
}

// S2: Implements the equation
// out = in[0] ⊕ in[1] ⊕ (2 • in[2]) ⊕ (3 • in[3])
template S2() { 
    signal input in[4];
    signal output out;
    component num2bits[4];
    component xor[3];

    for (var i = 0; i < 2; i++) {
        num2bits[i] = Num2Bits(8);
        num2bits[i].in <== in[i];
    }

    num2bits[2] = Num2Bits(8);
    num2bits[2].in <-- TBox(0, in[2]);

    num2bits[3] = Num2Bits(8);
    num2bits[3].in <-- TBox(1, in[3]);

    xor[0] = XorBits();
    xor[0].a <== num2bits[0].out;
    xor[0].b <== num2bits[1].out;

    xor[1] = XorBits();
    xor[1].a <== xor[0].out;
    xor[1].b <== num2bits[2].out;

    xor[2] = XorBits();
    xor[2].a <== xor[1].out;
    xor[2].b <== num2bits[3].out;

    component b2n = Bits2Num(8);
    for (var i = 0; i < 8; i++) {
        b2n.in[i] <== xor[2].out[i];
    }

    out <== b2n.out;
}

// S3: Implements the equation
// out = (3 • in[0]) ⊕ in[1] ⊕ in[2] ⊕ (2 • in[3])
template S3() {
    signal input in[4];
    signal output out;
    component num2bits[4];
    component xor[3];

    for (var i = 1; i < 3; i++) {
        num2bits[i] = Num2Bits(8);
        num2bits[i].in <== in[i];
    }

    num2bits[0] = Num2Bits(8);
    num2bits[0].in <-- TBox(1, in[0]);

    num2bits[3] = Num2Bits(8);
    num2bits[3].in <-- TBox(0, in[3]);

    xor[0] = XorBits();
    xor[0].a <== num2bits[0].out;
    xor[0].b <== num2bits[1].out;

    xor[1] = XorBits();
    xor[1].a <== xor[0].out;
    xor[1].b <== num2bits[2].out;

    xor[2] = XorBits();
    xor[2].a <-- num2bits[3].out;
    xor[2].b <== xor[1].out;

    component b2n = Bits2Num(8);
    for (var i = 0; i < 8; i++) {
        b2n.in[i] <== xor[2].out[i];
    }

    out <== b2n.out;
}