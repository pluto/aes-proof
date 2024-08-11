pragma circom 2.1.9;

include "cipher.circom";
include "transformations.circom";

template EncryptCTR(l,nk){
        signal input plainText[l];
        signal input iv[16];
        signal input key[nk * 4];
        signal output cipher[l];

        var n = l\16;
        if(l%16 > 0){
                n = n + 1;
        }

        component toBlocks = ToBlocks(l);
        toBlocks.stream <== plainText;

        component aes[n];

        signal cipherBlocks[n][4][4];
        component AddCipher[n];

        component generateCtrBlocks = GenerateCounterBlocks(n);
        generateCtrBlocks.iv <== iv;

        for(var i = 0 ; i < n; i++){
                aes[i] = Cipher(nk);
                aes[i].key <== key;
                aes[i].block <== generateCtrBlocks.counterBlocks[i];

                AddCipher[i] = AddCipher();
                AddCipher[i].state <== toBlocks.blocks[i];
                AddCipher[i].cipher <== aes[i].cipher;

                cipherBlocks[i] <== AddCipher[i].newState;
        }

        component toStream = ToStream(n,l);
        toStream.blocks <== cipherBlocks;

        cipher <== toStream.stream;
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