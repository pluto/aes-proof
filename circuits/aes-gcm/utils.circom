pragma circom 2.1.9;

include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/mux1.circom";
include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/gates.circom";

// n is the number of bytes to convert to bits
template BytesToBits(n_bytes) {
    signal input in[n_bytes];
    signal output out[n_bytes*8];
    component num2bits[n_bytes];
    for (var i = 0; i < n_bytes; i++) {
        num2bits[i] = Num2Bits(8);
        num2bits[i].in <== in[i];
        for (var j = 7; j >=0; j--) {
            out[i*8 + j] <== num2bits[i].out[7 -j];
        }
    }
}

// n is the number of bytes we want
template BitsToBytes(n) {
    signal input in[n*8];
    signal output out[n];
    component bits2num[n];
    for (var i = 0; i < n; i++) {
        bits2num[i] = Bits2Num(8);
        for (var j = 0; j < 8; j++) {
            bits2num[i].in[7 - j] <== in[i*8 + j];
        }
        out[i] <== bits2num[i].out;
    }
}

// XORs two arrays of bits
template XorBits(){
        signal input a[8];
        signal input b[8];
        signal output out[8];

    component xor[8];
    for (var i = 0; i < 8; i++) {
        xor[i] = XOR();
        xor[i].a <== a[i];
        xor[i].b <== b[i];
        out[i] <== xor[i].out;
    }
}

// XORs two bytes
template XorByte(){
        signal input a;
        signal input b;
        signal output out;

        component abits = Num2Bits(8);
        abits.in <== a;

        component bbits = Num2Bits(8);
        bbits.in <== b;

        component XorBits = XorBits();
        XorBits.a <== abits.out;
        XorBits.b <== bbits.out;

        component num = Bits2Num(8);
        num.in <== XorBits.out;

        out <== num.out;
}

// XOR n bytes
template XORBLOCK(n_bytes){
    signal input a[n_bytes];
    signal input b[n_bytes];
    signal output out[n_bytes];

    component xorByte[n_bytes];
    for (var i = 0; i < n_bytes; i++) {
        xorByte[i] = XorByte();
        xorByte[i].a <== a[i];
        xorByte[i].b <== b[i];
        out[i] <== xorByte[i].out;
    }
}

// multiplexer for arrays of length n
template ArrayMux(n) {
    signal input a[n];      // First input array
    signal input b[n];      // Second input array
    signal input sel;       // Selector signal (0 or 1)
    signal output out[n];   // Output array

    for (var i = 0; i < n; i++) {
        // If sel = 0, out[i] = a[i]
        // If sel = 1, out[i] = b[i]
        out[i] <== (b[i] - a[i]) * sel + a[i];
    }
}

// parse LE bits to int
template ParseLEBytes64() {
    signal input in[64];
    signal output out;
    var temp = 0;

    // Iterate through the input bits
    for (var i = 7; i >= 0; i--) {
        for (var j = 0; j < 8; j++) {
            // Shift the existing value left by 1 and add the new bit
            var IDX = i*8+j;
            temp = temp * 2 + in[IDX];
        }
    }

    // Assign the final value to the output signal
    out <-- temp;
}

// parse BE bits as bytes and log them. Assumes that the number of bytes logged is a multiple of 8.
template ParseAndLogBitsAsBytes(N_BYTES){
    var N_BITS = N_BYTES * 8;
    signal input in[N_BITS];
    component Parser = ParseBEBitsToBytes(N_BYTES);
    for (var i=0; i<N_BITS; i++){
        Parser.in[i] <== in[i];
    }
    for (var i=0; i<N_BYTES / 8; i++){
        log("in[", i, "]=", 
            Parser.out[i*8+0],  Parser.out[i*8+1],  Parser.out[i*8+2],  Parser.out[i*8+3], 
        Parser.out[i*8+4],  Parser.out[i*8+5],  Parser.out[i*8+6],  Parser.out[i*8+7]  
        ); 
    }
}

// parse BE bits to bytes. 
template ParseBEBitsToBytes(N_BYTES) {
    var N_BITS = N_BYTES * 8;
    signal input in[N_BITS];
    signal output out[N_BYTES];
    // var temp[8] = [0,0,0,0,0,0,0,0];

    // Iterate through the input bits
    var temp[N_BYTES];
    for (var i = 0; i < N_BYTES; i++) {
        temp[i] = 0; 
        for (var j = 7; j >= 0; j--) {
            temp[i] += 2**j * in[i*8 + 7 - j];
        }
    }

    for (var i=0; i< N_BYTES; i++) {
        out[i] <-- temp[i];
    }
}

// parse 64-bits to integer value
template ParseBEBytes64() {
    signal input in[64];
    signal output out;
    var temp = 0;

    // Iterate through the input bits
    for (var i = 0; i < 64; i++) {
        // Shift the existing value left by 1 and add the new bit
        temp = temp * 2 + in[i];
    }

    // Assign the final value to the output signal
    out <-- temp;
}

template BitwiseRightShift(n, r) {
    signal input in[n];
    signal output out[n];
    for (var i=0; i<r; i++) {
        out[i] <== 0;
    }
    for (var i=r; i<n; i++) {
        out[i] <== in[i-r];
    }
}


template BitwiseLeftShift(n, r) {
    signal input in[n];
    signal output out[n];
    for (var i=0; i<n-r; i++) {
        out[i] <== in[i+r];
    }
    for (var i=n-r; i<n; i++) {
        out[i] <== 0;
    }
}


template BitwiseXor(n) {
    signal input a[n];
    signal input b[n];
    signal output out[n];
    signal mid[n];

    for (var k=0; k<n; k++) {
        mid[k] <== a[k]*b[k];
        out[k] <== a[k] + b[k] - 2*mid[k];
    }
}

template BitwiseAnd(n) {
    signal input a[n];
    signal input b[n];
    signal output out[n];

    for (var k=0; k<n; k++) {
        out[k] <== a[k]*b[k];
    }
}

template BitwiseOr(n) {
    signal input a[n];
    signal input b[n];
    signal output out[n];

    for (var i=0; i<n; i++) {
        out[i] <== a[i] + b[i] - a[i]*b[i];
    }
}

// compute the OR of n inputs, each m bits wide
template OrMultiple(n, m) {
    signal input inputs[n][m];
    signal output out[m];

    signal mids[n][m];
    mids[0] <== inputs[0];

    component ors[n-1];
    for(var i=0; i<n-1; i++) {
        ors[i] = BitwiseOr(m);
        ors[i].a <== mids[i];
        ors[i].b <== inputs[i+1];
        mids[i+1] <== ors[i].out;
    }

    out <== mids[n-1];
}

// compute the XOR of n inputs, each m bits wide
template XorMultiple(n, m) {
    signal input inputs[n][m];
    signal output out[m];

    signal mids[n][m];
    mids[0] <== inputs[0];

    component xors[n-1];
    for(var i=0; i<n-1; i++) {
        xors[i] = BitwiseXor(m);
        xors[i].a <== mids[i];
        xors[i].b <== inputs[i+1];
        mids[i+1] <== xors[i].out;
    }

    out <== mids[n-1];
}


// reverse the byte order in a 16 byte array
template ReverseByteArray128() {
    signal input in[128];
    signal output out[128];

    for (var i = 0; i < 16; i++) {
        for (var j = 0; j < 8; j++) {
            out[j + 8*i] <== in[(15-i)*8 +j];
        }
    }
}
// in a 128-bit array, reverse the byte order in the first 64 bits, and the second 64 bits
template ReverseByteArrayHalves128() {
    signal input in[128];
    signal output out[128];

    for (var i=0; i<8; i++){
        for (var j=0; j<8; j++){
            var SWAP_IDX = 56-(i*8)+j;
            out[i*8+j] <== in[SWAP_IDX]; 
        }
    }
    for (var i=0; i<8; i++){
        for (var j=0; j<8; j++){
            var SWAP_IDX = 56-(i*8)+j+64;
            out[i*8+j+64] <== in[SWAP_IDX]; 
        }
    }
}

// Increment a 32-bit word, represented as a 4-byte array
//
//    \  :  /       \  :  /       \  :  /       \  :  /       \  :  /
// `. __/ \__ .' `. __/ \__ .' `. __/ \__ .' `. __/ \__ .' `. __/ \__ .'
// _ _\     /_ _ _ _\     /_ _ _ _\     /_ _ _ _\     /_ _ _ _\     /_ _
//    /_   _\       /_   _\       /_   _\       /_   _\       /_   _\
//  .'  \ /  `.   .'  \ /  `.   .'  \ /  `.   .'  \ /  `.   .'  \ /  `.
//    /  |  \       /  :  \       /  :  \       /  :  \       /  |  \
//       |                                                       |
//    \  |  /                                                 \  |  /
// `. __/ \__ .'                                           `. __/ \__ .'
// _ _\     /_ _                                           _ _\     /_ _
//    /_   _\                            __                   /_   _\
//  .'  \ /  `.               .-.       /  |                .'  \ /  `.
//    /  |  \               __| |__     `| |                  /  |  \
//       |                 |__   __|     | |                  
//    \  |  /                 | |       _| |_                 \  |  /
// `. __/ \__ .'              '-'      |_____|             `. __/ \__ .'
// _ _\     /_ _                                           _ _\     /_ _
//    /_   _\                                                 /_   _\
//  .'  \ /  `.                                             .'  \ /  `.
//    /  |  \                                                 /  |  \
//       |                                                       |
//    \  |  /       \  :  /       \  :  /       \  :  /       \  |  /
// `. __/ \__ .' `. __/ \__ .' `. __/ \__ .' `. __/ \__ .' `. __/ \__ .'
// _ _\     /_ _ _ _\     /_ _ _ _\     /_ _ _ _\     /_ _ _ _\     /_ _
//    /_   _\       /_   _\       /_   _\       /_   _\       /_   _\
//  .'  \ /  `.   .'  \ /  `.   .'  \ /  `.   .'  \ /  `.   .'  \ /  `.
//    /  :  \       /  :  \       /  :  \       /  :  \       /  :  \
template IncrementWord() {
    signal input in[4];
    signal output out[4];
    signal carry[4];
    carry[3] <== 1;

    component IsGreaterThan[4];
    component mux[4];
    for (var i = 3; i >= 0; i--) {
        // check to carry overflow
        IsGreaterThan[i] = GreaterThan(8);
        IsGreaterThan[i].in[0] <== in[i] + carry[i];
        IsGreaterThan[i].in[1] <== 0xFF;

        // multiplexer to select the output
        mux[i] = Mux1();
        mux[i].c[0] <== in[i] + carry[i];
        mux[i].c[1] <== 0x00;
        mux[i].s <== IsGreaterThan[i].out;
        out[i] <== mux[i].out;

        // propagate the carry to the next bit
        if (i > 0) {
            carry[i - 1] <== IsGreaterThan[i].out;
        }
    }
}

template Contains(n) {
    assert(n > 0);
    /*
    If `n = p` for this large `p`, then it could be that this template
    returns the wrong value if every element in `array` was equal to `in`.
    This is EXTREMELY unlikely and iterating this high is impossible anyway.
    But it is better to check than miss something, so we bound it by `2**254` for now.
    */
    assert(n < 2**254);
    signal input in;
    signal input array[n];
    signal output out;

    var accum = 0;
    component equalComponent[n];
    for(var i = 0; i < n; i++) {
        equalComponent[i] = IsEqual();
        equalComponent[i].in[0] <== in;
        equalComponent[i].in[1] <== array[i];
        accum = accum + equalComponent[i].out;
    }

    component someEqual = IsZero();
    someEqual.in <== accum;

    // Apply `not` to this by 1-x
    out <== 1 - someEqual.out;
}

template ArraySelector(m, n) {
    signal input in[m][n];
    signal input index;
    signal output out[n];
    assert(index >= 0 && index < m);

    signal selector[m];
    for (var i = 0; i < m; i++) {
        selector[i] <-- index == i ? 1 : 0;
        selector[i] * (1 - selector[i]) === 0; 
    }

    var sum = 0;
    for (var i = 0; i < m; i++) {
        sum += selector[i];
    }
    sum === 1;

    signal sums[n][m+1];
    // note: loop order is column-wise, not row-wise
    for (var j = 0; j < n; j++) {
        sums[j][0] <== 0;
        for (var i = 0; i < m; i++) {
            sums[j][i+1] <== sums[j][i] + in[i][j] * selector[i];
        }
        out[j] <== sums[j][m];
    }
}

template Selector(n) {
    signal input in[n];
    signal input index;
    signal output out;
    assert(index >= 0 && index < n);

    signal selector[n];
    for (var i = 0; i < n; i++) {
        selector[i] <-- index == i ? 1 : 0;
        selector[i] * (1 - selector[i]) === 0;
    }

    var sum = 0;
    for (var i = 0; i < n; i++) {
        sum += selector[i];
    }
    sum === 1;

    signal sums[n+1];
    sums[0] <== 0;
    for (var i = 0; i < n; i++) {
        sums[i+1] <== sums[i] + in[i] * selector[i];
    }

    out <== sums[n];
}
