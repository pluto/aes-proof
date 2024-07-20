template Multiplier() {
    signal input a[3];
    signal input b;
    signal input c;
    signal output d;
    signal output e;

    d <== a[0]*b;
    e <== a[1]+b;
    c === d*e + a[2];
    
}

component main {public [a, b, c]}= Multiplier();