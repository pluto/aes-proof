pragma circom 2.1.9;

include "mul.circom";

// Computes carryless POLYVAL multiplication over GF(2^128) in constant time.
//
// Method described at:
// <https://www.bearssl.org/constanttime.html#ghash-for-gcm>
//
// POLYVAL multiplication is effectively the little endian equivalent of
// GHASH multiplication, aside from one small detail described here:
//
// <https://crypto.stackexchange.com/questions/66448/how-does-bearssls-gcm-modular-reduction-work/66462#66462>
//
// > The product of two bit-reversed 128-bit polynomials yields the
// > bit-reversed result over 255 bits, not 256. The BearSSL code ends up
// > with a 256-bit result in zw[], and that value is shifted by one bit,
// > because of that reversed convention issue. Thus, the code must
// > include a shifting step to put it back where it should
//
// This shift is unnecessary for POLYVAL and has been removed.
//
// ref: https://github.com/RustCrypto/universal-hashes/blob/master/polyval/src/backend/soft64.rs#L151
template MUL() {
    signal input a[2][64];
    signal input b[2][64];
    signal output out[2][64];

    // variable aliases to make indexing logic easier to state
    signal h[3][64];
    signal y[3][64];
    signal h_r[3][64];
    signal y_r[3][64];

    h[0] <== a[0];
    h[1] <== a[1];
    y[0] <== b[0];
    y[1] <== b[1];
    component Revs[4];
    for (var i = 0; i < 2; i++) {
        Revs[i] = REV64();
        Revs[i].in <== h[i];
        h_r[i] <== Revs[i].out;
    }
    for (var i = 0; i < 2; i++) {
        Revs[i+2] = REV64();
        Revs[i+2].in <== y[i];
        y_r[i] <== Revs[i+2].out;
    }

    // h2 = h0^h1; y2 = y0^y1
    component Xors[4];
    for (var i = 0; i < 4; i++) Xors[i] = BitwiseXor(64);
    Xors[0].a <== h[0];
    Xors[0].b <== h[1];
    h[2] <== Xors[0].out;
    Xors[1].a <== y[0];
    Xors[1].b <== y[1];
    y[2] <== Xors[1].out;

    // h2_r = h0_r^h1_r; y2_r = y0_r^y1_r
    Xors[2].a <== h_r[0];
    Xors[2].b <== h_r[1];
    h_r[2] <== Xors[2].out;
    Xors[3].a <== y_r[0];
    Xors[3].b <== y_r[1];
    y_r[2] <== Xors[3].out;

    // z0 = bmul64(y0, h0); z1 = bmul64(y1, h1); z2 = bmul64(y2, h2);
    // z0_h = bmul64(y0_r, h0_r); z1_h = bmul64(y1_r, h1_r); z2_h = bmul64(y2_r, h2_r);
    component BMUL64_z[6];
    signal z[3][64];
    signal zh[3][64];
    for (var i = 0; i < 3; i++) {
        BMUL64_z[i] = BMUL64();
        BMUL64_z[i].x <== y[i];
        BMUL64_z[i].y <== h[i];
        z[i] <== BMUL64_z[i].out;

        BMUL64_z[i+3] = BMUL64();
        BMUL64_z[i+3].x <== y_r[i];
        BMUL64_z[i+3].y <== h_r[i];
        zh[i] <== BMUL64_z[i+3].out;
    }

    // _z2 = z0 ^ z1 ^ z2;
    // _z2h = z0h ^ z1h ^ z2h;
    signal _z2[64];
    signal _zh[3][64];
    component XorMultiples[2];
    XorMultiples[0] = XorMultiple(3, 64);
    XorMultiples[0].inputs <== z;
    _z2 <== XorMultiples[0].out;

    XorMultiples[1] = XorMultiple(3, 64);
    XorMultiples[1].inputs <== zh;
    _zh[0] <== XorMultiples[1].out;
    _zh[1] <== zh[1];
    _zh[2] <== zh[2];

    // z0h = rev64(z0h) >> 1;
    // z1h = rev64(z1h) >> 1;
    // _z2h = rev64(_z2h) >> 1;
    // signal _zh[3][64];
    signal __zh[3][64];
    component Revs_zh[3];
    component RightShifts_zh[3];
    for (var i = 0; i < 3; i++) {
        Revs_zh[i] = REV64();
        RightShifts_zh[i] = BitwiseRightShift(64, 1);
        Revs_zh[i].in <== zh[i];
        RightShifts_zh[i].in <== Revs_zh[i].out;
        __zh[i] <== RightShifts_zh[i].out;
    }

    // let v0 = z0;
    // let mut v1 = z0h ^ z2;
    // let mut v2 = z1 ^ z2h;
    // let mut v3 = z1h;
    signal v[4][64];
    component Xors_v[2];
    v[0] <== z[0];
    v[3] <== __zh[1];
    Xors_v[0] = BitwiseXor(64);
    Xors_v[0].a <== __zh[0];
    Xors_v[0].b <== _z2;
    v[1] <== Xors_v[0].out;
    Xors_v[1] = BitwiseXor(64);
    Xors_v[1].a <== z[1];
    Xors_v[1].b <== __zh[2];
    v[2] <== Xors_v[1].out;


    // _v2 = v2 ^ v0 ^ (v0 >> 1) ^ (v0 >> 2) ^ (v0 >> 7);
    // _v1 = v1 ^ (v0 << 63) ^ (v0 << 62) ^ (v0 << 57);
    // _v3 = v3 ^ _v1 ^ (_v1 >> 1) ^ (_v1 >> 2) ^ (_v1 >> 7);
    // __v2 = _v2 ^ (_v1 << 63) ^ (_v1 << 62) ^ (_v1 << 57);
    signal _v2[64];
    signal _v1[64];
    signal _v3[64];
    signal __v2[64];
    component RS_v[6];
    component LS_v[6];

    component XorMultiples_R[2];
    component XorMultiples_L[2];
    for (var i=0; i<2; i++) {
        XorMultiples_R[i] = XorMultiple(5, 64);
        XorMultiples_L[i] = XorMultiple(4, 64);
    }

    RS_v[0] = BitwiseRightShift(64, 1);
    RS_v[0].in <== v[0];
    RS_v[1] = BitwiseRightShift(64, 2);
    RS_v[1].in <== v[0];
    RS_v[2] = BitwiseRightShift(64, 7);
    RS_v[2].in <== v[0];
   
    LS_v[0] = BitwiseLeftShift(64, 63);
    LS_v[0].in <== v[0];
    LS_v[1] = BitwiseLeftShift(64, 62);
    LS_v[1].in <== v[0];
    LS_v[2] = BitwiseLeftShift(64, 57);
    LS_v[2].in <== v[0];

    XorMultiples_R[0].inputs <== [v[2], v[0], RS_v[0].out, RS_v[1].out, RS_v[2].out];
    _v2 <== XorMultiples_R[0].out;
    XorMultiples_L[0].inputs <== [v[1], LS_v[0].out, LS_v[1].out, LS_v[2].out];
    _v1 <== XorMultiples_L[0].out;

    RS_v[3] = BitwiseRightShift(64, 1);
    RS_v[3].in <== _v1;
    RS_v[4] = BitwiseRightShift(64, 2);
    RS_v[4].in <== _v1;
    RS_v[5] = BitwiseRightShift(64, 7);
    RS_v[5].in <== _v1;

    LS_v[3] = BitwiseLeftShift(64, 63);
    LS_v[3].in <== _v1;
    LS_v[4] = BitwiseLeftShift(64, 62);
    LS_v[4].in <== _v1;
    LS_v[5] = BitwiseLeftShift(64, 57);
    LS_v[5].in <== _v1;

    XorMultiples_R[1].inputs <== [v[3], _v1, RS_v[3].out, RS_v[4].out, RS_v[5].out];
    _v3 <== XorMultiples_R[1].out;
    XorMultiples_L[1].inputs <== [_v2, LS_v[0].out, LS_v[1].out, LS_v[2].out];
    __v2 <== XorMultiples_L[1].out;

    out <== [__v2, _v3];
}

// Multiplication in GF(2)[X], truncated to the low 64-bits, with “holes”
// (sequences of zeroes) to avoid carry spilling.
//
// When carries do occur, they wind up in a "hole" and are subsequently masked
// out of the result.
//
// ref: https://github.com/RustCrypto/universal-hashes/blob/master/polyval/src/backend/soft64.rs#L206
template BMUL64() {
    signal input x[64];
    signal input y[64];
    signal output out[64];

    signal xs[4][64];
    signal ys[4][64];
    // var masks[4] = [0x1111111111111111, 0x2222222222222222, 0x4444444444444444, 0x8888888888888888];
    var masks[4][64] = [
        [0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,
         0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1],
        [0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,
         0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0],
        [0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,
         0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0],
        [1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,
         1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0]];

    component ands[3][4];
    for (var i = 0; i < 4; i++) {
        ands[0][i] = BitwiseAnd(64);
        ands[0][i].a <== masks[i];
        ands[0][i].b <== x;
        xs[i] <== ands[0][i].out;

        ands[1][i] = BitwiseAnd(64);
        ands[1][i].a <== masks[i];
        ands[1][i].b <== y;
        ys[i] <== ands[1][i].out;
    }

    // w_{i,j} = x_j * y_{i-j%4}
    component muls[4][4];
    // z_i = XOR(w_{i,0}, w_{i,1}, w_{i,2}, w_{i,3})
    component xor_multiples[4];
    signal z_mid[4][4][64];
    signal z[4][64];
    for (var i = 0; i < 4; i++) {
        for (var j = 0; j < 4; j++) {
            var Y_INDEX = (i - j) % 4;
            muls[i][j] = Mul64();
            muls[i][j].src1 <== xs[j];
            muls[i][j].src2 <== ys[Y_INDEX];
            z_mid[i][j] <== muls[i][j].out;
        }

        xor_multiples[i] = XorMultiple(4, 64);
        xor_multiples[i].inputs <== z_mid[i];
        z[i] <== xor_multiples[i].out;
    }

    // z_masked[i] = z[i] & masks[i]
    signal z_masked[4][64];
    for (var i = 0; i < 4; i++) {
        ands[2][i] = BitwiseAnd(64);
        ands[2][i].a <== masks[i];
        ands[2][i].b <== z[i];
        z_masked[i] <== ands[2][i].out;
    }

    // out = z_masked[0] | z_masked[1] | z_masked[2] | z_masked[3]
    component or_multiple = OrMultiple(4, 64);
    or_multiple.inputs <== z_masked;
    out <== or_multiple.out;
}

// todo: verify this is what was actually meant
template REV64(){
    signal input in[64];
    signal output out[64];

    for (var i = 0; i < 64; i++) {
        out[i] <== in[63 - i];
    }
}
