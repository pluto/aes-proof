// Copyright © 2022, Electron Labs
pragma circom 2.0.0;

include "aes_256_encrypt.circom";
include "helper_functions.circom";

/// AES-256 CTR template
/// We will need to change this to AES-128 CTR
/// Which means we will need to change the aes_256_encrypt.circom to aes_128_encrypt.circom
template AES256CTR(n_bits)
{
    var msg_len = n_bits/8;
    signal input in[n_bits];
    signal input ctr[128];
    /// TODO(WJ 2024-08-09): change to correct key bytes
    /// Question: 1920 / 8 = 240? why is there key 16 bits less than the input size?
    /// niavely it should be 128 * 8 = 1240 bits?
    signal input ks[1920];

    /// output is amount of input bits
    signal output out[n_bits];

    /// What is EK?
    var EK[128];
    var p_index = 0, c_index = 0;
    var ctr_t[128] = ctr;
    var out_t[msg_len][8];

    /// iterator varirables 
    var i, j, k, l;

    /// components for 16 bit blocks
    component aes_256_encrypt_1[msg_len/16];
    component xor_1[msg_len/16][4][4][32];
    component num2bits_1[msg_len/16];
    component bits2num_1[msg_len/16];

    for(i=0; i<msg_len/16; i++)
    {
        /// for each block encrypt with aes;
        aes_256_encrypt_1[i] = AES256Encrypt();
        for(j=0; j<128; j++) aes_256_encrypt_1[i].in[j] <== ctr_t[j];
        
        // This is the expanded key. Let's see if it's done correctly. 
        for(j=0; j<1920; j++) aes_256_encrypt_1[i].ks[j] <== ks[j];

        EK = aes_256_encrypt_1[i].out;

        for(j=0; j<4; j++)
        {
            for(k=0; k<4; k++)
            {
                for(l=0; l<8; l++)
                {
                    xor_1[i][j][k][l] = XOR();
                    xor_1[i][j][k][l].a <== in[i*128+j*32+k*8+l];
                    xor_1[i][j][k][l].b <== EK[j*32+k*8+l];

                    out[i*128+j*32+k*8+l] <== xor_1[i][j][k][l].out;
                }
            }
        }
        bits2num_1[i] = Bits2Num(32);
        num2bits_1[i] = Num2Bits(32);
        for(j=0; j<4; j++) 
        {
            for(k=0; k<8; k++) bits2num_1[i].in[j*8+k] <== ctr_t[j*8+7-k];
        }
        num2bits_1[i].in <== bits2num_1[i].out + 1;
        for(j=0; j<4; j++)
        {
            for(k=0; k<8; k++) ctr_t[j*8+k] = num2bits_1[i].out[j*8+7-k];
        }
    }
}