// from: https://github.com/crema-labs/aes-circom/tree/main/circuits
pragma circom 2.1.9;

include "circomlib/circuits/comparators.circom";
include "./ff.circom";

template SBox128() {
    signal input in;
    signal output out;

    signal inv <== FieldInv()(in);
    signal invBits[8] <== Num2Bits(8)(inv);
    signal outBits[8] <== AffineTransform()(invBits);
    out <== Bits2Num(8)(outBits);
}
