// Copyright © 2022, Electron Labs
pragma circom 2.0.0;

include "aes_emulation_tables.circom";
include "aes_emulation.circom";
include "helper_functions.circom";


/// AES-256 Encrypt template
/// We will need to change this to AES-128 Encrypt
/// Which means we will need to change the key size to 128
/// And the number of rounds to 10

// The number of full rounds for this key size (Not the last partial round)
const ROUNDS = 10 - 1

template AES128Encrypt()
{
    /// Input is 128 bit of plaintext
    signal input in[128]; // ciphertext
    
    // Key schedule for initial, final, and between each full round
    key_size <== (4 + 4 + ROUNDS * 4) * 32
    signal input ks[key_size];
    
    /// Output is 128 bit of ciphertext
    signal output out[128]; // plaintext

    var ks_index = 0;
    
    /// TODO(WJ 2024-08-09): what are these?
    /// 4 x 32 mattrix of field elements
    var s[4][32], t[4][32];
    
    var i,j,k,l,m;
    
    component xor_1[4][32];
    /// state initialization, might have to do with key size being 240byte rather 256byte
    for(i=0; i<4; i++) // adding round key
    {
        for(j=0; j<32; j++)
        {
            xor_1[i][j] = XOR();
            /// example sequece [[0..31],[33..64]
            /// i see so they are 32 bit chunks
            /// Then XOR each chuck with parts of the keys 
            xor_1[i][j].a <== in[i*32+j]; // plaintext
            
            
            
            /// XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
            // (i+ks_index)*32+j
            xor_1[i][j].b <== ks[(i+ks_index)*32+j]; // key schedule

            s[i][j] = xor_1[i][j].out;
        }
    }
    ks_index += 4;

    component xor_2[13][4][3][32];
    component bits2num_1[13][4][4];
    component num2bits_1[13][4][4];
    component xor_3[13][4][32];


    /// 14 rounds of encryption TODO(WJ 2024-08-09): Change this to 10 rounds to fit AES-128
    for(i=0; i<13; i++) // 13 iterations maybe one extra at the end or happened to generate the key above?
    {
        /// 5 steps in each round
        /// Step 1: SubBytes
        /// Step 2: ShiftRows:
        /// Step 3: MixColumns
        /// Step 4: AddRoundKeys
        /// 
        for(j=0; j<4; j++) // 4 iterations
        {
            for(k=0; k<4; k++) // 4 iterations // COLUMN MIXING ALGORITHM
            {
                /// initialize trace space for 13x4x4 uses of bits2num and num2bit
                bits2num_1[i][j][k] = Bits2Num(8);
                num2bits_1[i][j][k] = Num2Bits(32);
                /// 0 - 3 based on sum of index j and k
                /// grabbing 1 x 32 bit row from state (top to bottom)
                var s_tmp[32] = s[(j+k)%4];
                /// big endian indexing through the bits to num
                for(l=0; l<8; l++) bits2num_1[i][j][k].in[l] <== s_tmp[k*8+7-l];
                /// I think this is the sbox lookup, not sure any more
                num2bits_1[i][j][k].in <-- emulated_aesenc_enc_table(k, bits2num_1[i][j][k].out);

                if(k==0) // first row unchanged (not shifted)
                {
                    for(l=0; l<4; l++)
                    {
                        for(m=0; m<8; m++)
                        { // setting up one part of a xor
                            xor_2[i][j][k][l*8+m] = XOR();
                            xor_2[i][j][k][l*8+m].a <== num2bits_1[i][j][k].out[l*8+7-m];
                        }
                    }
                }
                else if(k<3) // 2nd, 3rd rows are shifted by 1, 2 respectively (clever indexing here is how they do this)
                {
                    for(l=0; l<4; l++) // 4
                    {
                        for(m=0; m<8; m++) // 8 -> 32 bits = 1 row of state
                        {
                            xor_2[i][j][k-1][l*8+m].b <== num2bits_1[i][j][k].out[l*8+7-m];

                            xor_2[i][j][k][l*8+m] = XOR();
                            xor_2[i][j][k][l*8+m].a <== xor_2[i][j][k-1][l*8+m].out;
                        }
                    }
                }
                /// Thought 1: is  this maybe just copying  memory?
                else
                {
                    for(l=0; l<4; l++)
                    {
                        for(m=0; m<8; m++)
                        {
                            xor_2[i][j][k-1][l*8+m].b <== num2bits_1[i][j][k].out[l*8+7-m];

                            xor_3[i][j][l*8+m] = XOR();
                            xor_3[i][j][l*8+m].a <== xor_2[i][j][k-1][l*8+m].out;
                        }
                    }
                }
            }
        }
        for(j=0; j<4; j++)
        {
            for(l=0; l<32; l++)
            {
                xor_3[i][j][l].b <== ks[(j+ks_index)*32+l];
                s[j][l] = xor_3[i][j][l].out;
            }
        }
        ks_index += 4;
    } // end of round

    component bits2num_2[16];
    var s_bytes[16];

    for(i=0; i<4; i++)
    {
        for(j=0; j<4; j++)
        {
            bits2num_2[i*4+j] = Bits2Num(8);
            for(k=0; k<8; k++) bits2num_2[i*4+j].in[k] <== s[i][j*8+7-k];
            s_bytes[i*4+j] = bits2num_2[i*4+j].out;
        }
    }

    /// Row shifting and substitution
    component row_shifting = EmulatedAesencRowShifting();
    component sub_bytes = EmulatedAesencSubstituteBytes();
    for(i=0; i<16; i++) row_shifting.in[i] <== s_bytes[i];
    for(i=0; i<16; i++) sub_bytes.in[i] <== row_shifting.out[i];

    component num2bits_2[16];

    for(i=0; i<4; i++)
    {
        for(j=0; j<4; j++)
        {
            num2bits_2[i*4+j] = Num2Bits(8);
            num2bits_2[i*4+j].in <== sub_bytes.out[i*4+j];
            for(k=0; k<8; k++) s[i][j*8+k] = num2bits_2[i*4+j].out[7-k];
        }
    }

    component xor_4[4][32];

    for(i=0; i<4; i++) // final key XOR?
    {
        for(j=0; j<32; j++)
        {
            xor_4[i][j] = XOR();
            xor_4[i][j].a <== s[i][j];
            xor_4[i][j].b <== ks[(i+ks_index)*32+j];

            s[i][j] = xor_4[i][j].out;
        }
    }

    for(i=0; i<4; i++)
    {
        for(j=0; j<32; j++) out[i*32+j] <== s[i][j];
    }
}


