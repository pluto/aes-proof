// from: https://github.com/crema-labs/aes-circom/tree/main/circuits
pragma circom 2.1.9;

include "sbox128.circom";
include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/gates.circom";
include "../utils.circom";

// Rotates an array of bytes to the left by a specified rotation
template Rotate(rotation, length) {
    assert(rotation < length);
    signal input bytes[length];
    signal output rotated[length];

    for(var i = 0; i < length - rotation; i++) {
        rotated[i] <== bytes[i + rotation];
    }

    for(var i = length - rotation; i < length; i++) {
        rotated[i] <== bytes[i - length + rotation];
    }
}

// Substitutes each byte in a word using the S-Box
template SubstituteWord() {
    signal input bytes[4];
    signal output substituted[4];

    component sbox[4];

    for(var i = 0; i < 4; i++) {
        sbox[i] = SBox128();
        sbox[i].in <== bytes[i];
        substituted[i] <== sbox[i].out;
    }
}

// Outputs a round constant for a given round number
template RCon(round) {
    signal output out[4];

    assert(round > 0 && round <= 10);

    var rcon[10][4] = [
        [0x01, 0x00, 0x00, 0x00],
        [0x02, 0x00, 0x00, 0x00],
        [0x04, 0x00, 0x00, 0x00],
        [0x08, 0x00, 0x00, 0x00],
        [0x10, 0x00, 0x00, 0x00],
        [0x20, 0x00, 0x00, 0x00],
        [0x40, 0x00, 0x00, 0x00],
        [0x80, 0x00, 0x00, 0x00],
        [0x1b, 0x00, 0x00, 0x00],
        [0x36, 0x00, 0x00, 0x00]
    ];

    out <== rcon[round-1];
}


// XORs two words (arrays of 4 bytes each)
template XorWord() {
    signal input bytes1[4];
    signal input bytes2[4];

    component n2b[4 * 2];
    component b2n[4];
    component xor[4][8];

    signal output out[4];

    for(var i = 0; i < 4; i++) {
        n2b[2 * i] = Num2Bits(8);
        n2b[2 * i + 1] = Num2Bits(8);
        n2b[2 * i].in <== bytes1[i];
        n2b[2 * i + 1].in <== bytes2[i];
        b2n[i] = Bits2Num(8);

        for (var j = 0; j < 8; j++) {
            xor[i][j] = XOR();
            xor[i][j].a <== n2b[2 * i].out[j];
            xor[i][j].b <== n2b[2 * i + 1].out[j];
            b2n[i].in[j] <== xor[i][j].out;
        }

        out[i] <== b2n[i].out;
    }
}

// Multiplies a byte by an array of bits
template MulByte(){
    signal input a;
    signal input b[8];
    signal output c[8];

    for (var i = 0; i < 8; i++) {
        c[i] <== a * b[i];
    }
}


//convert stream of plain text to blocks of 16 bytes
template ToBlocks(l){
        signal input stream[l];

        var n = l\16;
        if(l%16 > 0){
                n = n + 1;
        }
        signal output blocks[n][4][4];

        var i, j, k;

        for (var idx = 0; idx < l; idx++) {
                blocks[i][k][j] <== stream[idx];
                k = k + 1;
                if (k == 4){
                        k = 0;
                        j = j + 1;
                        if (j == 4){
                                j = 0;
                                i = i + 1;
                        }
                }
        }

        if (l%16 > 0){
               blocks[i][k][j] <== 1;
               k = k + 1;
        }
}

// convert blocks of 16 bytes to stream of bytes
template ToStream(n,l){
        signal input blocks[n][4][4];

        signal output stream[l];

        var i, j, k;

        while(i*16 + j*4 + k < l){
                stream[i*16 + j*4 + k] <== blocks[i][k][j];
                k = k + 1;
                if (k == 4){
                        k = 0;
                        j = j + 1;
                        if (j == 4){
                                j = 0;
                                i = i + 1;
                        }
                }
        }
}

template AddCipher(){
    signal input state[4][4];
    signal input cipher[4][4];
    signal output newState[4][4];

    component xorbyte[4][4];

    for (var i = 0; i < 4; i++) {
        for (var j = 0; j < 4; j++) {
            xorbyte[i][j] = XorByte();
            xorbyte[i][j].a <== state[i][j];
            xorbyte[i][j].b <== cipher[i][j];
            newState[i][j] <== xorbyte[i][j].out;
        }
    }
}

// converts iv to counter blocks
// iv is 16 bytes
template GenerateCounterBlocks(n){
        assert(n < 0xffffffff);
        signal input iv[16];
        signal output counterBlocks[n][4][4];

        var ivr[16] = iv;

        component toBlocks[n];

        for (var i = 0; i < n; i++) {
                toBlocks[i] = ToBlocks(16);
                toBlocks[i].stream <-- ivr;
                counterBlocks[i] <== toBlocks[i].blocks[0];
                ivr[15] = (ivr[15] + 1)%256;
                if (ivr[15] == 0){
                        ivr[14] = (ivr[14] + 1)%256;
                        if (ivr[14] == 0){
                                ivr[13] = (ivr[13] + 1)%256;
                                if (ivr[13] == 0){
                                        ivr[12] = (ivr[12] + 1)%256;
                                }
                        }
                }

        }
}