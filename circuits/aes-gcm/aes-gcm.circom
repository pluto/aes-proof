pragma circom 2.1.9;

include "../aes-ctr/ctr.circom";
include "../ghash/ghash.circom";
include "../aes-ctr/cipher.circom";
include "circomlib/circuits/bitify.circom";


/// AES-GCM with 128 bit key according to: https://nvlpubs.nist.gov/nistpubs/legacy/sp/nistspecialpublication800-38d.pdf
/// 
/// Parameters:
/// l: length of the plaintext
///
/// Inputs:
/// key: 128-bit key
/// iv: initialization vector
/// plainText: plaintext to be encrypted
/// additionalData: additional data to be authenticated
///
/// Outputs:
/// cipherText: encrypted ciphertext
/// authTag: authentication tag
/// 
template AESGCM(l) {
    // Inputs
    signal input key[16]; // 128-bit key
    signal input iv[12]; // IV length is 96 bits (12 bytes)
    signal input plainText[l];
    signal input additionalData[16]; // AAD length is 128 bits (16 bytes)

    // Outputs
    signal output cipherText[l];
    signal output authTag[16]; // Authentication tag length is 128 bits (16 bytes)

    // Step 1: Let H = CIPHK(0128)
    component zeroBlock = Num2Bits(128);
    zeroBlock.in <== 0;
    component cipherH = Cipher(4); // 128-bit key -> 4 32-bit words -> 10 rounds
    cipherH.key <== key;
    cipherH.block <== zeroBlock.out;
    signal H[128];
    H <== cipherH.cipher;

    // Step 2: Define a block, J0 with 96 bits of iv and 32 bits of 0s
    // you can of the 96bits as a nonce and the 32 bits of 0s as an integer counter
    signal J0[128];
    for (var i = 0; i < 96; i++) {
        J0[i] <== iv[i];
    }
    for (var i = 96; i < 127; i++) {
        J0[i] <== 0;
    }
    J0[127] <== 1;
    /// NOTE(WJ 2024-09-09): There is a way to handle IVs that are not 96 bits in the nist spec involving padding and GHASHing the IV
    /// since we set the size for the iv here we don't need to handle it


    // Step 3: Let C = GCTRK(inc32(J0), P)
    component incJ0 = Increment32();
    incJ0.in <== J0;
    component gctr = GCTR(l, nk);
    gctr.key <== key;
    gctr.iv <== incJ0.out;
    gctr.plainText <== plainText;
    cipherText <== gctr.cipherText;

    // Step 4: Let u and v
    var u = 128 * Math.ceil(cipherText.length / 128) - cipherText.length;
    var v = 128 * Math.ceil(additionalData.length / 128) - additionalData.length;

    // Step 5: Define a block, S
    component ghash = GHASH();
    ghash.H <== H;
    ghash.A <== additionalData;
    ghash.C <== cipherText;
    ghash.u <== u;
    ghash.v <== v;
    signal S[128];
    S <== ghash.out;

    // Step 6: Let T = MSBt(GCTRK(J0, S))
    component gctrT = GCTR(16, nk);
    gctrT.key <== key;
    gctrT.iv <== J0;
    gctrT.plainText <== S;
    authTag <== gctrT.cipherText;

}