pragma circom 2.1.9;

include "polyval_gfmul.circom";

// Implement POLYVAL for testing purposes
template POLYVAL(n_msg_bits) {
    signal input msg[n_msg_bits]; 
    signal input H[128]; 
    signal output out[128];

    component POLYVAL_GFMUL ;
    signal tags[n_msg_bits][128];
    signal xors[n_msg_bits][128];


    // for (var i=0; i<128; i++){ xors[0][i] <== 0; }

    for (var i=0; i<128; i++){ out[i] <== 0; }
}
