pragma circom 2.1.9;

include "mul.circom";

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
    signal zs_mid[4][4][64];
    signal zs[4][64];
    for (var i = 0; i < 4; i++) {
        for (var j = 0; j < 4; j++) {
            var Y_INDEX = (i - j) % 4;
            muls[i][j] = Mul64();
            muls[i][j].src1 <== xs[j];
            muls[i][j].src2 <== ys[Y_INDEX];
            zs_mid[i][j] <== muls[i][j].out;
        }

        xor_multiples[i] = XorMultiple(4, 64);
        xor_multiples[i].inputs <== zs_mid[i];
        zs[i] <== xor_multiples[i].out;
    }

    // zs_masked[i] = zs[i] & masks[i]
    signal zs_masked[4][64];
    for (var i = 0; i < 4; i++) {
        ands[2][i] = BitwiseAnd(64);
        ands[2][i].a <== masks[i];
        ands[2][i].b <== zs[i];
        zs_masked[i] <== ands[2][i].out;
    }

    // out = zs_masked[0] | zs_masked[1] | zs_masked[2] | zs_masked[3]
    component or_multiple = OrMultiple(4, 64);
    or_multiple.inputs <== zs_masked;
    out <== or_multiple.out;
}