pragma circom 2.1.9;

include "helper_functions.circom";

// 64-bit wrapping multiplication. Assumes MSB is first (Big E)
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
    log(partials[62][63]);

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

// todo: deprecate
template Mul()
{
    signal input src1[64];
    signal input src2[64];
    signal output out[128];

    var i, j, k;

    var dst_bytes[2][64];
    var src1_bytes[64], src2_bytes[64];

    for(i=0; i<8; i++)
    {
        for(j=0; j<8; j++)
        {
            src1_bytes[i*8+j] = src1[i*8+7-j];
            src2_bytes[i*8+j] = src2[i*8+7-j];
        }
    }

    component xor_1[64][2][64];

    var const_bytes[64];
    for(i=0; i<64; i++)
    {
        dst_bytes[0][i] = 0;
        dst_bytes[1][i] = 0;
        const_bytes[i] = 0;
    }
    const_bytes[63] = 1;

    for(i=0; i<64; i++)
    {
        var src1_bytes_t[64];
        for(j=0; j<64; j++)
        {
            src1_bytes_t[j] = src1_bytes[j] * src2_bytes[i];
            xor_1[i][0][j] = XOR();
            
            xor_1[i][0][j].a <== dst_bytes[1][j];
            xor_1[i][0][j].b <== src1_bytes_t[j];

            dst_bytes[1][j] = xor_1[i][0][j].out;
        }
        for(j=0; j<63; j++)
        {
            dst_bytes[0][j] = dst_bytes[0][j+1];
        }
        dst_bytes[0][63] = 0;

        var const_bytes_t[64];
        for(j=0; j<64; j++)
        {
            const_bytes_t[j] = const_bytes[j] * dst_bytes[1][0];
            xor_1[i][1][j] = XOR();

            xor_1[i][1][j].a <== dst_bytes[0][j];
            xor_1[i][1][j].b <== const_bytes_t[j];

            dst_bytes[0][j] = xor_1[i][1][j].out;
        }
        for(j=0; j<63; j++)
        {
            dst_bytes[1][j] = dst_bytes[1][j+1];
        }
        dst_bytes[1][63] = 0;
    }

    for(i=0; i<2; i++)
    {
        for(j=0; j<8; j++)
        {
            for(k=0; k<8; k++) out[i*64+j*8+k] <== dst_bytes[i][j*8+7-k];
        }
    }

}
