pragma circom 2.1.9;

include "polyval_gfmul.circom";

// Implement POLYVAL for testing purposes
template POLYVAL(BLOCKS) {
    signal input msg[BLOCKS][128]; 
    signal input H[128]; 
    signal output out[128];

    // reverse msg and H, store in msg_ and H_
    signal msg_[128];
    signal H_[128];
    component ReverseByteHalves[3];
    for (var i=0; i<3; i++){ ReverseByteHalves[i] = ReverseByteArrayHalves128();}
    ReverseByteHalves[0].in <-- msg[0]; msg_ <-- ReverseByteHalves[0].out;
    ReverseByteHalves[1].in <-- H; H_ <-- ReverseByteHalves[1].out;

    // signal tags[BLOCKS][128];
    // signal xors[BLOCKS][128];
    component POLYVAL_GFMUL = POLYVAL_GFMUL();
    for (var i=0; i<2; i++){ 
        for (var j=0; j<64; j++){ 
            POLYVAL_GFMUL.a[i][j] <== msg_[i*64+j];
            // POLYVAL_GFMUL.a[1-i][j] <== msg_[0][i*64+j];
            POLYVAL_GFMUL.b[i][j] <== H_[i*64+j];
        }
    }

    // for (var i=0; i<128; i++){ xors[0][i] <== 0; }
    // for (var i=0; i<128; i++){ out[i] <== 0; }
    signal _out[128];
    for (var i=0; i<2; i++){ 
        for (var j=0; j<64; j++){ 
            // out[i*64 + j] <== POLYVAL_GFMUL.out[i][63-j];
            _out[i*64 + j] <== POLYVAL_GFMUL.out[i][j];
        }
    }

    ReverseByteHalves[2].in <== _out; 
    out <-- ReverseByteHalves[2].out;

    component Logger3 = ParseAndLogBitsAsBytes(16);
    log("out");
    Logger3.in <== out;
}
