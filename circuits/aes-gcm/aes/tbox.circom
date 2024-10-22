// from: https://github.com/crema-labs/aes-circom/tree/main/circuits
pragma circom 2.1.9;

include "./ff.circom";

template TBox(index) {
    signal input subindex;
    signal output out;

    if (index == 0) {
        out <== FieldMul2()(subindex);
    } else if (index == 1) {
        out <== FieldMul3()(subindex);
    }
}