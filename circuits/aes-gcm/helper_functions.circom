pragma circom 2.1.9;

include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/gates.circom";
include "circomlib/circuits/comparators.circom";

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

    // // constrain each input bit to be either 0 or 1
    // for (var i = 0; i < 64; i++) {
    //     in[i] * (1 - in[i]) === 0;
    // }
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

template IntRightShift(n, x)
{	
    signal input in;
    signal output out;
    
    component num2bits = Num2Bits(n);
    num2bits.in <== in;

    component bits2num = Bits2Num(n);
    var i;
    for(i=0; i<n; i++)
    {
        if(i+x<n) bits2num.in[i] <== num2bits.out[i+x];
        else bits2num.in[i] <== 0;
    } 
    out <== bits2num.out;
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

template IntLeftShift(n, x)
{	
    signal input in;
    signal output out;
    
    component num2bits = Num2Bits(n);
    num2bits.in <== in;

    component bits2num = Bits2Num(n);
    for(var i=0; i<n; i++)
    {
        if(i<x) bits2num.in[i] <== 0;
        else bits2num.in[i] <== num2bits.out[i-x];
    }
    out <== bits2num.out;
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

template IntXor(n)
{
    signal input a;
    signal input b;

    signal output out;

    component num2bits[2];
    num2bits[0] = Num2Bits(n);
    num2bits[1] = Num2Bits(n);

    num2bits[0].in <== a;
    num2bits[1].in <== b;
    
    component xor[n];
    for(var i=0; i<n; i++) xor[i] = XOR();

    component bits2num = Bits2Num(n);
    for(var i=0; i<n; i++)
    {
        xor[i].a <== num2bits[0].out[i];
        xor[i].b <== num2bits[1].out[i];

        bits2num.in[i] <== xor[i].out;
    }

    out <== bits2num.out;
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

template IntAnd(n)
{
    signal input a;
    signal input b;

    signal output out;

    component num2bits[2];
    num2bits[0] = Num2Bits(n);
    num2bits[1] = Num2Bits(n);

    num2bits[0].in <== a;
    num2bits[1].in <== b;
    component and[n];
    for(var i=0; i<n; i++) and[i] = AND();

    component bits2num = Bits2Num(n);
    for(var i=0; i<n; i++)
    {
        and[i].a <== num2bits[0].out[i];
        and[i].b <== num2bits[1].out[i];
        bits2num.in[i] <== and[i].out;
    }

    out <== bits2num.out;
}

template IntOr(n)
{
    signal input a;
    signal input b;

    signal output out;

    component num2bits[2];
    num2bits[0] = Num2Bits(n);
    num2bits[1] = Num2Bits(n);

    num2bits[0].in <== a;
    num2bits[1].in <== b;
    component or[n];
    for(var i=0; i<n; i++) or[i] = OR();

    component bits2num = Bits2Num(n);
    for(var i=0; i<n; i++)
    {
        or[i].a <== num2bits[0].out[i];
        or[i].b <== num2bits[1].out[i];
        bits2num.in[i] <== or[i].out;
    }

    out <== bits2num.out;
}

template Typecast(in_size, in_bits, out_bits)
{

    var out_size = (in_size*in_bits)/out_bits;
    signal input in[in_size];
    signal output out[out_size];

    var i, j, k;

    component num2bits[in_size];
    for(i=0; i<in_size; i++) num2bits[i] = Num2Bits(in_bits);

    component bits2num[out_size];
    for(i=0; i<out_size; i++) bits2num[i] = Bits2Num(out_bits);

    if(in_bits > out_bits)
    {
        var ratio = in_bits/out_bits;
        for(i=0; i<in_size; i++)
        {
            num2bits[i].in <== in[i];
            for(j=0; j<ratio; j++){
                var index = i*ratio + j;
                for(k=0; k<out_bits; k++) bits2num[index].in[k] <== num2bits[i].out[j*out_bits+k];
                out[index] <== bits2num[index].out;
            }
        }
    }
    else if(out_bits > in_bits)
    {
        var ratio = out_bits/in_bits;
        for(i=0; i<out_size; i++)
        {
            for(j=0; j<ratio; j++)
            {
                var index = i*ratio + j;
                num2bits[index].in <== in[index];
                for(k=0; k<in_bits; k++) bits2num[i].in[j*in_bits+k] <== num2bits[index].out[k];
            }
            out[i] <== bits2num[i].out;
        }
    }
}

template SumMultiple(n) {
    signal input nums[n];
    signal output sum;

    signal sums[n];
    sums[0] <== nums[0];

    for(var i=1; i<n; i++) {
        sums[i] <== sums[i-1] + nums[i];
    }

    sum <== sums[n-1];
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

// select the index-th element from an array of total elements
// via the argument:
// Sum_0^n (IsEqual(index, i) * in[i])
template IndexSelector(total) {
    signal input in[total];
    signal input index;
    signal output out;

    //maybe add (index<total) check later when we decide number of bits

    component calcTotal = SumMultiple(total);
    component equality[total];

    for(var i=0; i<total; i++){
        equality[i] = IsEqual();
        equality[i].in[0] <== i;
        equality[i].in[1] <== index;
        calcTotal.nums[i] <== equality[i].out * in[i];
    }

    out <== calcTotal.sum;
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

// in a 128-bit array, reverse the halves.
template ReverseHalves128() {
    signal input in[128];
    signal output out[128];

    for (var i=0; i<64; i++){
        var SWAP_IDX = 64+i;
        out[i] <== in[SWAP_IDX]; 
    }
    for (var i=64; i<128; i++){
        var SWAP_IDX = i-64;
        out[i] <== in[SWAP_IDX]; 
    }
}
