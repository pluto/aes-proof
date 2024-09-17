pragma circom 2.1.9;

include "../aes-ctr/ctr.circom";
include "ghash.circom";
include "../aes-ctr/cipher.circom";
include "circomlib/circuits/bitify.circom";
include "utils.circom";
include "gctr.circom";
include "helper_functions.circom";


/// AES-GCM with 128 bit key authenticated encryption according to: https://nvlpubs.nist.gov/nistpubs/legacy/sp/nistspecialpublication800-38d.pdf
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
    signal input aad[16]; // AAD length is 128 bits (16 bytes)

    // Outputs
    signal output cipherText[l];
    signal output authTag[16]; //   Authentication tag length is 128 bits (16 bytes)

    component zeroBlock = ToBlocks(16);
    for (var i = 0; i < l; i++) {
        zeroBlock.stream[i] <== 0;
    }

    // Step 1: Let H = CIPHK(0128)
    component cipherH = Cipher(4); // 128-bit key -> 4 32-bit words -> 10 rounds
    cipherH.key <== key;
    cipherH.block <== zeroBlock.blocks[0];
    // signal H[16]; // bit stuff
    // H <== cipherH.cipher;

    // Step 2: Define a block, J0 with 96 bits of iv and 32 bits of 0s
    // you can of the 96bits as a nonce and the 32 bits of 0s as an integer counter
    // TODO(WJ 2024-09-16): make this a block of bytes not bits

    component J0builder = ToBlocks(16);
    for (var i = 0; i < 12; i++) {
        J0builder.stream[i] <== iv[i];
    }
    for (var i = 12; i < 16; i++) {
        J0builder.stream[i] <== 0;
    }
    component J0WordIncrementer = IncrementWord();
    J0WordIncrementer.in <== J0builder.blocks[0][3];
    signal J0[4][4];
    for (var i = 0; i < 3; i++) {
        J0[i] <== J0builder.blocks[0][i];
    }
    // TODO(WJ 2024-09-16): maybe need to increment this again before passing to gctr. Check section 7.3 of nist spec
    J0[3] <== J0WordIncrementer.out;


    // Step 3: Let C = GCTRK(inc32(J0), P)
    component gctr = GCTR(l, 4);
    gctr.key <== key;
    gctr.initialCounterBlock <== J0;
    gctr.plainText <== plainText;

    // Step 4: Let u and v
    var u = 128 * (l \ 128) - l;
    // 16 = len(AAD)
    // when we handle dynamic aad lengths, we'll need to change this
    var v = 0;


    // compute length of ghash input (concat of the above stuff)
    // A => aad data, single block
    // C => ciphertext data, 
    // compute num_blocks for the actual ghash function (need to compute length)
    //                aad + 
    var ghashblocks = 1 + (l\16 + 1) + 1; // blocksize is 16 bytes
    signal ghashMessage[ghashblocks][4][4];

    // set aad as first block
    for (var i=0; i < 4; i++) {
        for (var j=0; j < 4; j++) {
            ghashMessage[0][i][j] <== aad[i*4+j];
        }
    }
    // set cipher text block padded
    component ciphertextBlocks = ToBlocks(l);
    ciphertextBlocks.stream <== gctr.cipherText;
    for (var i=0; i<l\16; i++) {
        ghashMessage[i+1] <== ciphertextBlocks.blocks[i];
    }
  
    // length of aad = 128 = 0x80 as 64 bit number
    ghashMessage[ghashblocks-1][0] <== [0x00, 0x00, 0x00, 0x00];
    ghashMessage[ghashblocks-1][1] <== [0x00, 0x00, 0x00, 0x80];

    // TODO: constrain len to be u64 range.
    var len = (l\16) * 128;
    for (var i=0; i<8; i++) {
        var byte_value = 0;
        for (var j=0; j<8; j++) {
            byte_value += (len >> i*8+j) & 1;
        }
        ghashMessage[ghashblocks-1][((i*8+j)\32)+2][i%4] <== byte_value;
    }

    // Step 5: Define a block, S
    // needs to take in the number of blocks
    component ghash = GHASH(ghashblocks);
    ghash.HashKey <== cipherH.cipher;
    // S = GHASHH (A || 0^v || C || 0^u || [len(A)] || [len(C)]).
    ghash.msg <== ghashMessage; // TODO(WJ 2024-09-16): this is wrong
    // In Steps 4 and 5, the AAD and the ciphertext are each appended with the minimum number of
    // ‘0’ bits, possibly none, so that the bit lengths of the resulting strings are multiples of the block
    // size. The concatenation of these strings is appended with the 64-bit representations of the
    // lengths of the AAD and the ciphertext, and the GHASH function is applied to the result to
    // produce a single output block.

    signal S[128];
    // S should be a block defined by

    S <== ghash.tag;
    // signal input HashKey[2][64]; // Hash subkey (128 bits)
    // signal input msg[NUM_BLOCKS][2][64]; // Input blocks (each 128 bits)

    // Step 6: Let T = MSBt(GCTRK(J0, S))
    component gctrT = GCTR(16, 4);
    gctrT.key <== key;
    gctrT.initialCounterBlock <== J0;
    gctrT.plainText <== S;
    authTag <== gctrT.cipherText;
}