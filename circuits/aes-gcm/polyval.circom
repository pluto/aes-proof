pragma circom 2.1.9;

include "polyval_gfmul.circom";

// Implement POLYVAL for testing purposes
template POLYVAL(BLOCKS) {
    signal input msg[BLOCKS][128]; 
    signal input H[128]; 
    signal output out[128];

    // reverse msg and H, store in msg_ and H_
    component ReverseBytes[2];
    ReverseBytes[0]=ReverseHalves128(); ReverseBytes[1]=ReverseHalves128();
    signal msg_[128];
    signal H_[128];
    ReverseBytes[0].in <== msg[0];
    msg_ <== ReverseBytes[0].out;
    ReverseBytes[1].in <== H;
    H_ <== ReverseBytes[1].out;

    // log _H and _m
    component Logger1 = ParseAndLogBitsAsBytes(16);
    Logger1.in <== H_;
    component Logger2 = ParseAndLogBitsAsBytes(16);
    Logger2.in <== msg_;

    // signal tags[BLOCKS][128];
    // signal xors[BLOCKS][128];
    component POLYVAL_GFMUL = POLYVAL_GFMUL();
    for (var i=0; i<2; i++){ 
        for (var j=0; j<64; j++){ 
            POLYVAL_GFMUL.a[1-i][j] <== msg_[i*64+j];
            // POLYVAL_GFMUL.a[1-i][j] <== msg_[0][i*64+j];
            POLYVAL_GFMUL.b[1-i][j] <== H_[i*64+j];
        }
    }

    // for (var i=0; i<128; i++){ xors[0][i] <== 0; }
    // for (var i=0; i<128; i++){ out[i] <== 0; }
    for (var i=0; i<2; i++){ 
        for (var j=0; j<64; j++){ 
            out[i*64 + j] <== POLYVAL_GFMUL.out[i][j];
        }
    }
    component Logger3 = ParseAndLogBitsAsBytes(16);
    Logger3.in <== out;
}
