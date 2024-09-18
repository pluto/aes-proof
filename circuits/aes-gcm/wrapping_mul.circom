pragma circom 2.1.9;

include "helper_functions.circom";

// 64-bit BE wrapping multiplication.
// Implements multiplication mod 2^{64}.
template WrappingMul64() {
    signal input a[64];
    signal input b[64];
    signal output out[64];

    // Intermediate signals for partial products
    // partial[i,j corresponds to AND(a[i], b[j])
    signal partials[64][64];
    for (var i = 0; i < 64; i++) {
        for (var j = 0; j < 64; j++) {
            partials[i][j] <== a[i] * b[j];
        }
    }

    // 65, not 64, to allow for an extra carry without having to fiddle with overflow
    var sum[65];
    for (var i=0; i<65; i++) { sum[i]=0; }

    for (var i = 0; i<64; i++) {
        for (var j = 0; i+j<64; j++) {
            var SUM_IDX = 64-i-j;
            sum[SUM_IDX] += partials[63-i][63-j];

            // covers the case that sum[i+j]=3 or more, due to prior carries
            while (sum[SUM_IDX] > 1) {
                sum[SUM_IDX] -= 2;
                sum[SUM_IDX-1] += 1;
            }
        }
    }

    // Perform modular reduction (keep only the lower 64 bits)
    for (var i = 0; i < 64; i++) {
        out[i] <-- sum[i+1];
    }
}
