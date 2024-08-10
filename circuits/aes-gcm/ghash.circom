pragma circom 2.0.0;

include "gfmul_int.circom";
include "helper_functions.circom";

// GHASH computes the authentication tag for AES-GCM.
// Inputs:
// - `H` the hash key
// - AAD authenticated additional data
// - M the message to authenticate
// 
// Outputs:
// - `result` the authentication tag
// TODO(TK 2024-08-10): rename - n_bits -> msg bytes?
template GHASH(n_bits)
{
    signal input in[n_bits]; // n-bit message input
    signal input H[128]; // hash key
    signal input T[2][64]; // TODO(TK 2024-08-10): doc
    signal output result[2][64]; // tag

    var msg_len = n_bits/8; // TODO(TK 2024-08-10): doc
    var current_res[2][64] = T, in_t[2][64]; // result intermediate state
    var i, j, k;
    var blocks = msg_len/16; 

    component xor_1[blocks][2][64];
    component gfmul_int_1[blocks];
    
    if(blocks != 0)
    {
        for(i=0; i<blocks; i++)
        {
            for(j=0; j<64; j++)
            {
                in_t[0][j] = in[2*i*64+j];
                in_t[1][j] = in[(2*i+1)*64+j];
            }

            for(j=0; j<2; j++)
            {
                for(k=0; k<64; k++)
                {
                    xor_1[i][j][k] = XOR();
                    xor_1[i][j][k].a <== current_res[j][k];
                    xor_1[i][j][k].b <== in_t[j][k];

                    current_res[j][k] = xor_1[i][j][k].out;
                }
            }

            gfmul_int_1[i] = GFMULInt();
            for(j=0; j<2; j++)
            {
                for(k=0; k<64; k++)
                {
                    gfmul_int_1[i].a[j][k] <== current_res[j][k];
                    gfmul_int_1[i].b[j][k] <== H[j*64+k];
                }
            }

            current_res = gfmul_int_1[i].res;
        }
    }

    for(i=0; i<2; i++)
    {
        for(j=0; j<64; j++) result[i][j] <== current_res[i][j];
    }
}

component main = GHASH(128);