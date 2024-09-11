pragma circom 2.1.9;

include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/mux1.circom";

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


template IncrementByte() {
    signal input in;
    signal output out;
    signal output carry;

    component IsGreaterThan = GreaterThan(8);
    component mux = Mux1();

    // check to carry overflow
    IsGreaterThan.in[0] <== in + 1;
    IsGreaterThan.in[1] <== 0xFF;

    mux.c[0] <== in + 1;
    mux.c[1] <== 0x00;
    mux.s <== IsGreaterThan.out;
    carry <== IsGreaterThan.out;

    out <== mux.out;

}