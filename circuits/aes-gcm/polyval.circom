pragma circom 2.1.9;

include "polyval_gfmul.circom";

// Implement POLYVAL for testing purposes
template POLYVAL(BLOCKS) {
    signal input msg[BLOCKS][128]; 
    signal input H[128]; 
    signal output out[128];

    signal H_bytes[16];
    component Parser = ParseBEBitsToBytes(16);
    // load parser with H and log output
    for (var i=0; i<128; i++){
        Parser.in[i] <== H[i];
    }
    for (var i=0; i<2; i++){
        log("h[", i, "]=", 
            Parser.out[i*8+0],  Parser.out[i*8+1],  Parser.out[i*8+2],  Parser.out[i*8+3], 
            Parser.out[i*8+4],  Parser.out[i*8+5],  Parser.out[i*8+6],  Parser.out[i*8+7]  ); 
    }

    signal tags[BLOCKS][128];
    // signal xors[BLOCKS][128];
    component POLYVAL_GFMUL = POLYVAL_GFMUL();
    for (var i=0; i<2; i++){ 
        for (var j=0; j<64; j++){ 
            POLYVAL_GFMUL.a[1-i][j] <== msg[0][i*64+j];
            POLYVAL_GFMUL.b[1-i][j] <== H[i*64+j];
        }
    }

    // for (var i=0; i<2; i++){ 
    //     for (var j=0; j<64; j++){ 
    //         log(POLYVAL_GFMUL.b[i][j]);
    // }}

    // for (var i=0; i<128; i++){ xors[0][i] <== 0; }

    // for (var i=0; i<128; i++){ out[i] <== 0; }
    for (var i=0; i<2; i++){ 
        for (var j=0; j<64; j++){ 
            out[i*64 + j] <== POLYVAL_GFMUL.out[i][j];
        }
    }
}
