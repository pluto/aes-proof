pragma circom 2.1.9;

// include "../circomlib/circuits/gates.circom";
include "helper_functions.circom";

// compute x * `in` over ghash polynomial
// ghash irreducible polynomial x^128 = x^7 + x^2 + x + 1
//
// spec: 
// https://tools.ietf.org/html/rfc8452#appendix-A
template ghash_GFMULX() {
    signal input in[128];
    signal output out[128];
    var msb = in[127];

    // v = in right-shifted by 1
    signal v[128];
    v[0] <== 0;
    for (var i = 1; i < 128; i++) { v[i] <== in[i-1]; }

    // if MSB set, assign irreducible poly bits, otherwise zero
    // irreducible_poly has 1s at positions 0, 1, 6, 127
    signal irreducible_poly[128];
    for (var i = 0; i < 128; i++) {
        if (i==0 || i == 1 || i==6 || i==127) { 
            irreducible_poly[i] <== msb;
        } else {
            irreducible_poly[i] <== 0;
        }
    }

    component xor = BitwiseXor(128);
    xor.a <== v;
    xor.b <== irreducible_poly;
    out <== xor.out;
}

// compute x * `in` over polyval polynomial
// polyval irreducible polynomial x^128 = x^127 + x^126 + x^121 + 1
//
// spec: 
// https://tools.ietf.org/html/rfc8452#appendix-A
//
// rust-crypto reference implementation: 
// https://github.com/RustCrypto/universal-hashes/blob/master/polyval/src/mulx.rs#L11
template polyval_GFMULX() {
    signal input in[128];
    signal output out[128];
    // v = in << 1;  observe that LE makes this less straightforward
    signal v[128];
    // if MSB set, assign irreducible poly bits, otherwise zero
    signal irreducible_poly[128];
    var msb = in[128 - 8];

    component left_shift = LeftShiftLE(1);
    for (var i = 0; i < 128; i++) {
        left_shift.in[i] <== in[i];
    }
    for (var i = 0; i < 128; i++) {
        v[i] <== left_shift.out[i];
    }

    // NOTE: LE logic explaining:
    // irreducible_poly has 1s at positions 1, 121, 126, 127
    // 0000 0001... <== bit at pos 7 encodes x^0
    // ...1100 0010 <== bits at pos 121, 122, 126 encode 127, 126, 121 respectively
    for (var i = 0; i < 128; i++) {
        if (i==7 || i == 120 || i==121 || i==126) { 
            irreducible_poly[i] <== msb;
        } else {
            irreducible_poly[i] <== 0;
        }
    }

    component xor = BitwiseXor(128);
    xor.a <== v;
    xor.b <== irreducible_poly;
    out <== xor.out;
}


// Left shift a 128-bit little-endian array by `shift` bits
//
// example for 16 bit-array shifted by 1 bit:
// in  = [h g f e d c b a, p o n m l k j i]
// mid1= [a b c d e f g h, i j k l m n o p] // swap order of bits in each byte
// mid2= [0 a b c d e f g, h i j k l m n o] // shift bits right by 1
// out = [g f e d c b a 0, o n m l k j i h] // swap order of bits in each byte
// TODO(TK 2024-08-15): optimize
template LeftShiftLE(shift) {
    signal input in[128];
    signal output out[128];
    signal mid_1[128];
    signal mid_2[128]; 

    for (var i = 0; i < 16; i++) {
        for (var j = 0; j < 8; j++) {
            mid_1[j + 8*i] <== in[7-j + 8*i];
        }
    }

    for (var i = 0; i < shift; i++) {
        mid_2[i] <== 0;
    }
    for (var i = shift; i < 128; i++) {
        mid_2[i] <== mid_1[i - shift];
    }

    for (var i = 0; i < 16; i++) {
        for (var j = 0; j < 8; j++) {
            out[j + 8*i] <== mid_2[7-j + 8*i];
        }
    }
}
