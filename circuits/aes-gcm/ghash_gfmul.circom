pragma circom 2.1.9;
include "polyval_gfmul.circom";
include "gfmulx.circom";

template GHASH_GFMUL() {
    signal input a[2][64];
    signal input b[2][64];
    signal output out[2][64];

    // TODO(TK 2024-09-18): produce a ghash mul wrapper
}
