pragma circom 2.0.0;

include "aes_256_ctr.circom";
include "aes_256_key_expansion.circom";

template AES_256_CTR_TEST(n_bits_msg) {

    // var aad_len = n_bits_aad/8;
    var msg_len = n_bits_msg/8;
    // assert(aad_len%16 == 0);
    assert(msg_len%16 == 0);
    signal input K1[256];
    signal input N[128];
    // signal input AAD[n_bits_aad];
    signal input CT[(msg_len+16)*8];
    signal output MSG[n_bits_msg];
    signal output success;
    var MSG_t[msg_len*8];

    var i;

    component aes_256_ctr = AES256CTR(msg_len*8);

    // populate key schedule
    var ks[1920];
    component key_expansion_1 = AES256KeyExpansion();
    for(i=0; i<256; i++) key_expansion_1.key[i] <== K1[i];
    ks = key_expansion_1.w;

    // populate tag for counter
    var TAG[128];
    for(i=0; i<128; i++) TAG[i] = CT[msg_len*8+i];

    // populate counter
    var CTR[128];
    for(i=0; i<128; i++) CTR[i] = TAG[i];
    CTR[15*8] = 1;

    // Cipher Text message
    var CT_msg[msg_len*8];
    for(i=0; i<msg_len*8; i++) CT_msg[i] = CT[i];


    for(i=0; i<msg_len*8; i++) aes_256_ctr.in[i] <== CT_msg[i];
    for(i=0; i<128; i++) aes_256_ctr.ctr[i] <== CTR[i]; 
    for(i=0; i<1920; i++) aes_256_ctr.ks[i] <== ks[i];
    MSG_t = aes_256_ctr.out;
}


component main = AES_256_CTR_TEST(256);