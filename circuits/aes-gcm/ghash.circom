pragma circom 2.0.0;

include "gfmul_int.circom";
include "helper_functions.circom";

// GHASH computes the authentication tag for AES-GCM.
// Inputs:
// - `H` the hash key
// - `AAD` authenticated additional data
// - `msg` the message to authenticate
// 
// Outputs:
// - `result` the authentication tag
template GHASH(n_msg_bits)
{
    signal input msg[n_msg_bits]; 
    signal input H[128]; 
    signal input AAD[2][64];
    signal output result[2][64];

    var n_msg_bytes = n_msg_bits/8; 
    var current_res[2][64] = AAD, in_t[2][64]; // result intermediate state
    var i, j, k;
    var n_msg_blocks = n_msg_bytes/16; 

    component xor_1[n_msg_blocks][2][64];
    component gfmul_int_1[n_msg_blocks];
    
    if(n_msg_blocks != 0)
    {
        // for each bit in the message
        for(i=0; i<n_msg_blocks; i++)
        {
            // 
            for(j=0; j<64; j++)
            {
                in_t[0][j] = msg[2*i*64+j];
                in_t[1][j] = msg[(2*i+1)*64+j];
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