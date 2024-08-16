pragma circom 2.1.9;

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
//
// Computes:
// let M = pad(AAD) || pad(msg) || len_64(AAD) || let_64(msg)
// X_0 = 0^128
// X_{i+1} = (X_i xor M_{i+1}) * H
// output: X_{n+1} where n is the number of blocks.
template GHASH(n_msg_bits) {
    signal input msg[n_msg_bits]; 
    signal input H[128]; 
    // signal input AAD[128]; // included in msg
    signal output out[128];

}

// {
//     signal input msg[n_msg_bits]; 
//     signal input H[128]; 
//     signal input AAD[2][64];
//     signal output result[2][64];

//     var n_msg_bytes = n_msg_bits/8; 
//     var current_res[2][64] = AAD, in_t[2][64]; // result intermediate state
//     var i, j, k;
//     var n_msg_blocks = n_msg_bytes/16; 

//     component xor_1[n_msg_blocks][2][64];
//     component gfmul_int_1[n_msg_blocks];
    
//     if(n_msg_blocks != 0)
//     {
//         // for each bit in the message
//         for(i=0; i<n_msg_blocks; i++)
//         {
//             // 
//             for(j=0; j<64; j++)
//             {
//                 in_t[0][j] = msg[2*i*64+j];
//                 in_t[1][j] = msg[(2*i+1)*64+j];
//             }

//             for(j=0; j<2; j++)
//             {
//                 for(k=0; k<64; k++)
//                 {
//                     xor_1[i][j][k] = XOR();
//                     xor_1[i][j][k].a <== current_res[j][k];
//                     xor_1[i][j][k].b <== in_t[j][k];

//                     current_res[j][k] = xor_1[i][j][k].out;
//                 }
//             }

//             gfmul_int_1[i] = GFMULInt();
//             for(j=0; j<2; j++)
//             {
//                 for(k=0; k<64; k++)
//                 {
//                     gfmul_int_1[i].a[j][k] <== current_res[j][k];
//                     gfmul_int_1[i].b[j][k] <== H[j*64+k];
//                 }
//             }

//             current_res = gfmul_int_1[i].res;
//         }
//     }

//     for(i=0; i<2; i++)
//     {
//         for(j=0; j<64; j++) result[i][j] <== current_res[i][j];
//     }
// }


// template POLYVAL(n_bits)
// {
//     var msg_len = n_bits/8;
//     signal input in[n_bits];
//     signal input H[128];
//     signal input T[2][64];
//     signal output result[2][64];

//     var current_res[2][64] = T, in_t[2][64];

//     var i, j, k;
//     var blocks = msg_len/16;

//     component xor_1[blocks][2][64];
//     component gfmul_int_1[blocks];
    
//     if(blocks != 0)
//     {
//         for(i=0; i<blocks; i++)
//         {
//             for(j=0; j<64; j++)
//             {
//                 in_t[0][j] = in[2*i*64+j];
//                 in_t[1][j] = in[(2*i+1)*64+j];
//             }

//             for(j=0; j<2; j++)
//             {
//                 for(k=0; k<64; k++)
//                 {
//                     xor_1[i][j][k] = XOR();
//                     xor_1[i][j][k].a <== current_res[j][k];
//                     xor_1[i][j][k].b <== in_t[j][k];

//                     current_res[j][k] = xor_1[i][j][k].out;
//                 }
//             }

//             gfmul_int_1[i] = GFMULInt();
//             for(j=0; j<2; j++)
//             {
//                 for(k=0; k<64; k++)
//                 {
//                     gfmul_int_1[i].a[j][k] <== current_res[j][k];
//                     gfmul_int_1[i].b[j][k] <== H[j*64+k];
//                 }
//             }

//             current_res = gfmul_int_1[i].res;
//         }
//     }

//     for(i=0; i<2; i++)
//     {
//         for(j=0; j<64; j++) result[i][j] <== current_res[i][j];
//     }
// }