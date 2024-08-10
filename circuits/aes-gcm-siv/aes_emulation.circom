// Copyright © 2022, Electron Labs
pragma circom 2.0.0;

include "aes_emulation_tables.circom";

/// template or row shifting
template EmulatedAesencRowShifting()
{

    /// Opperating on 16 bits at a time
    signal input in[16];
    signal output out[16];
    
    out[0]  <== in[0];
    out[1]  <== in[5];
    out[2]  <== in[10];
    out[3]  <== in[15];
    out[4]  <== in[4];
    out[5]  <== in[9];
    out[6]  <== in[14];
    out[7]  <== in[3];
    out[8]  <== in[8];
    out[9]  <== in[13];
    out[10] <== in[2];
    out[11] <== in[7];
    out[12] <== in[12];
    out[13] <== in[1];
    out[14] <== in[6];
    out[15] <== in[11];
}

/// Template for S-Box using the aes_encoding_rijndael_sbox
/// https://en.wikipedia.org/wiki/Rijndael_S-box
template EmulatedAesencSubstituteBytes()
{
    signal input in[16];
    signal output out[16];

    for(var i=0; i<16; i++) out[i] <-- emulated_aesenc_rijndael_sbox(in[i]);
    
}
