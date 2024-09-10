pragma circom 2.1.9;

include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/gates.circom";
include "circomlib/circuits/comparators.circom";

template BitwiseRightShift(n, r) {
    signal input in[n];
    signal output out[n];

    for(var i=0; i<n; i++){
        if(i+r>=n){
            out[i] <== 0;
        } else {
            out[i] <== in[i+r];
        }
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
    var j=0;
    for (var i=0; i<n; i++) {
        if (i < r) {
            out[i] <== 0;
        } else {
            out[i] <== in[j];
            j++;
        }
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

// reverse the order in an n-bit array
template ReverseArray(n) {
    signal input in[n];
    signal output out[n];

    for (var i = 0; i < n; i++) {
        out[i] <== in[n-i-1];
    }
}

// reverse the byte order in a 16 byte array
template ReverseByteArray() {
    signal input in[128];
    signal output out[128];

    for (var i = 0; i < 16; i++) {
        for (var j = 0; j < 8; j++) {
            out[j + 8*i] <== in[(15-i)*8 +j];
        }
    }
}

/// IncrementingFunction increments the integer represented by the 32 least significant bits of the input 128-bit value
/// and returns the result.
template Increment32() {
    signal input in[128];
    signal output out[128];

    // Copy the left-most 96 bits unchanged
    for (var i = 0; i < 96; i++) {
        out[i] <== in[i];
    }

    // Convert rightBits to an integer
    component rightBitsInt = Bits2Num(32);
    for (var i = 0; i < 32; i++) {
        rightBitsInt.in[i] <== in[96 + i];
    }

    // Debugging signal to check the integer value of rightBitsInt
    signal rightBitsValue <== rightBitsInt.out;

    // Constraint: Increment rightBitsInt
    // TODO(WJ 2024-09-09): handle overflow
    signal incremented <== rightBitsValue + 1;

    // Convert the incremented integer back to binary
    component num2bits = Num2Bits(32);
    num2bits.in <== incremented;
    signal incrementedBits[32];
    for (var i = 0; i < 32; i++) {
        incrementedBits[i] <== num2bits.out[i];
    }

    // TODO(WJ 2024-09-09): Check if this bit-reversal is needed.
    component reverseBits = ReverseArray(32);
    reverseBits.in <== incrementedBits;
    // Copy the incremented bits to the output
    for (var i = 0; i < 32; i++) {
        out[96 + i] <== reverseBits.out[i];
    }
}

/// IncrementingFunction increments the integer represented by the 32 least significant bits of the input 16-byte block
/// and returns the result.
template Increment32Block() {
    signal input in[4][4];
    signal output out[4][4];

    log("input:");
    log(in[0][0], in[0][1], in[0][2], in[0][3]);
    log(in[1][0], in[1][1], in[1][2], in[1][3]);
    log(in[2][0], in[2][1], in[2][2], in[2][3]);
    log(in[3][0], in[3][1], in[3][2], in[3][3]);
    // Copy the left-most 12 bytes unchanged
    for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 4; j++) {
            out[i][j] <== in[i][j];
        }
    }

    // Convert the last 4 bytes to an 32 bit number
    // signal bits[32];
    component bits2num = Bits2Num(32);
    component byte2bits[4];
    for (var i = 0; i < 4; i++) {
        byte2bits[i] = Num2Bits(8);
        byte2bits[i].in <== in[3][i];
        for (var j = 0; j < 8; j++) {
            bits2num.in[i * 8 + j] <== byte2bits[i].out[j];
        }
    }
    // TODO: handle overflow
    signal incremented <== bits2num.out + 1;

    // Convert the incremented integer back to binary
    component num2bits = Num2Bits(32);
    num2bits.in <== incremented;
    signal incrementedBits[32];
    for (var i = 0; i < 32; i++) {
        incrementedBits[i] <== num2bits.out[i];
    }


    // Convert the incremented bits back to four bytes and assign to out
    component bits2byte[4];
    signal outBytes[4];
    for (var i = 0; i < 4; i++) {
        bits2byte[i] = Bits2Num(8);
        for (var j = 0; j < 8; j++) {
            bits2byte[i].in[j] <== incrementedBits[i * 8 + j];
        }
        outBytes[i] <== bits2byte[i].out;
    }
    log("outBytes:");
    log(outBytes[0], outBytes[1], outBytes[2], outBytes[3]);
    out[3][0] <== outBytes[3];
    out[3][1] <== outBytes[2];
    out[3][2] <== outBytes[1];
    out[3][3] <== outBytes[0];
}

// Idea: try to increment the word by 1
// template IncrementWord() {
//     signal input in[4];
//     signal output out[4];

//     // Convert the 4 bytes to a 32-bit number
//     signal num <== in[0] * 0x1000000 + in[1] * 0x10000 + in[2] * 0x100 + in[3];

//     // Increment the number
//     signal incremented <== num + 1;

//     // Convert the incremented number back to 4 bytes
//     out[0] <== (incremented >> 24) & 0xFF;
//     out[1] <== (incremented >> 16) & 0xFF;
//     out[2] <== (incremented >> 8) & 0xFF;
//     out[3] <== incremented & 0xFF;
// }
