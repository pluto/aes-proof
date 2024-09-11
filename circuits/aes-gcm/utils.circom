pragma circom 2.1.9;

include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/mux1.circom";

template IncrementWord() {
    signal input in[4];
    signal output out[4];


    signal carry[4];
    carry[0] <== 1;
    // signal sum[4];

    component IsGreaterThan[4];
    component mux[4];

    for (var i = 0; i < 4; i++) {
        // check to carry overflow
        IsGreaterThan[i] = GreaterThan(8);
        IsGreaterThan[i].in[0] <== in[i];
        IsGreaterThan[i].in[1] <== 0xFF;

        mux[i] = Mux1();
        mux[i].c[0] <== in[i] + carry[i];
        mux[i].c[1] <== 0x00;
        mux[i].s <== IsGreaterThan[i].out;
        log("mux[i].out", mux[i].out);
        log("carry[i]", carry[i]);

        out[i] <== mux[i].out;

        if (i < 3) {
            carry[i + 1] <== IsGreaterThan[i].out;
        }
    }
}


template IncrementByte() {
    signal input in;
    signal output out;

    component IsGreaterThan = GreaterThan(8);
    component mux = Mux1();

    // check to carry overflow
    IsGreaterThan.in[0] <== in + 1;
    IsGreaterThan.in[1] <== 0xFF;

    log("in +1 ", in + 1);
    mux.c[0] <== in + 1;
    mux.c[1] <== 0x00;
    log("IsGreaterThan.out", IsGreaterThan.out);
    mux.s <== IsGreaterThan.out;
    log("mux.out", mux.out);

    out <== mux.out;

}