pragma circom 2.1.9;

include "polyval_gfmul.circom";

template POLYVAL(BLOCKS) {
    signal input msg[BLOCKS][128]; 
    signal input H[128]; 
    signal output out[128];

    // LE adjustments: reverse msg and H, store in msg_ and H_
    signal H_[128];
    signal msg_[BLOCKS][128];
    component ReverseByteHalves[BLOCKS+2];
    for (var i=0; i<BLOCKS+2; i++){ ReverseByteHalves[i] = ReverseByteArrayHalves128();}
    ReverseByteHalves[0].in <-- H; H_ <-- ReverseByteHalves[0].out;
    for (var i=2; i<BLOCKS+2; i++){ ReverseByteHalves[i].in <-- msg[i-2]; msg_[i-2] <-- ReverseByteHalves[i].out; }

    component XORS[BLOCKS]; component POLYVAL_GFMUL[BLOCKS];
    for (var i=0; i<BLOCKS; i++){ XORS[i] = BitwiseXor(128); }
    for (var i=0; i<BLOCKS; i++){ POLYVAL_GFMUL[i] = POLYVAL_GFMUL(); }

    signal mids[BLOCKS+1][128];
    for (var i=0; i<128; i++){ mids[0][i] <-- 0; }

    // xor and multiply
    for (var block=0; block<BLOCKS; block++){
        // xor
        XORS[block].a <== mids[block];
        XORS[block].b <== msg_[block];

        // multiply XORS[block].out * H_ 
        for (var i=0; i<2; i++){  for (var j=0; j<64; j++){ 
                POLYVAL_GFMUL[block].a[i][j] <== XORS[block].out[i*64+j];
                POLYVAL_GFMUL[block].b[i][j] <== H_[i*64+j];
        } }
        for (var i=0; i<2; i++){  for (var j=0; j<64; j++){ 
                mids[block+1][i*64+j] <== POLYVAL_GFMUL[block].out[i][j];
        } }
    }

    // need to reverse for BE once more
    signal _out[128]; _out <== mids[BLOCKS];
    ReverseByteHalves[1].in <== _out; 
    out <-- ReverseByteHalves[1].out;

    component Logger3 = ParseAndLogBitsAsBytes(16);
    log("out");
    Logger3.in <== out;
}
