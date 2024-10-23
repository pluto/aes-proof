pragma circom 2.1.9;

include "ghash-foldable.circom";
include "aes/cipher.circom";
include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/mux2.circom";
include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/gates.circom";
include "utils.circom";
include "gctr.circom";

/// AES-GCM with 128 bit key authenticated encryption according to: https://nvlpubs.nist.gov/nistpubs/legacy/sp/nistspecialpublication800-38d.pdf
/// 
/// Parameters:
/// l: length of the plaintext
///
/// Inputs:
/// key: 128-bit key
/// iv: initialization vector
/// plainText: plaintext to be encrypted
/// aad: additional data to be authenticated
///
/// Outputs:
/// cipherText: encrypted ciphertext
/// authTag: authentication tag
/// 
/// in thoery this should just do a single block,
template AESGCMFOLDABLE(TOTAL_BLOCKS) {
    // Inputs
    signal input key[16]; // 128-bit key
    signal input iv[12]; // IV length is 96 bits (12 bytes)
    signal input plainText[16]; // only fold 16 bytes at a time.
    signal input aad[16]; // AAD length is 128 bits (16 bytes)

    // Fold inputs
    signal input lastCounter[4];    // Always start at one, then bring forward last counter.
    signal input lastTag[16];       // Always start at zero, bring forward last tag.
    signal input foldedBlocks;      // running counter of how many blocks have folded, needed for ghash.

    // Fold outputs
    signal output counter[4];      

    // Outputs
    signal output cipherText[16];
    signal output authTag[16];

    component zeroBlock = ToBlocks(16);
    for (var i = 0; i < 16; i++) {
        zeroBlock.stream[i] <== 0;
    }

    // Step 1: Let HashKey = aes(key, zeroBlock)
    component cipherH = Cipher(); 
    cipherH.key <== key;
    cipherH.block <== zeroBlock.blocks[0];

    // Step 2: Define a block, J0 with 96 bits of iv and 32 bits of 0s
    component J0builder = ToBlocks(16);
    for (var i = 0; i < 12; i++) {
        J0builder.stream[i] <== iv[i];
    }
    // Use the fold counter as input. 
    for (var i = 12; i < 16; i++) {
        J0builder.stream[i] <== lastCounter[i%4]; // initialize to 0001. 
    }
    component J0WordIncrementer = IncrementWord();
    J0WordIncrementer.in <== J0builder.blocks[0][3];

    signal J0[4][4];
    for (var i = 0; i < 3; i++) {
        J0[i] <== J0builder.blocks[0][i];
    }
    J0[3] <== J0WordIncrementer.out;

    // Step 3: Let C = GCTRK(inc32(J0), P)
    component gctr = GCTR(16);
    gctr.key <== key;
    gctr.initialCounterBlock <== J0;
    gctr.plainText <== plainText;

    // Step 4: Let u and v, compute ghash steps. 
    // 
    // A => 1 => length of AAD (always at most 128 bits)
    // 0^v => padding bytes, none for v
    // C => l\16+1 => number of ciphertext blocks
    // 0^u => padding bytes, u value
    // len(A) => u64
    // len(b) => u64 (together, 1 block)
    // 
    // block count is aways 1 when folding a single block. 
    // TODO(WJ 2024-10-23): this is so strange. We are folding 3 ghash blocks and then using a selector? 
    // TODO(WJ 2024-10-23): it seems like we should just be folding 1 ghash block at a time then we wouldn't need the selector.
    // var blockCount  = 1 + (16%16 > 0 ? 1 : 0); // blocksize is 16 bytes
    // var ghashBlocks = 3; // always 3 blocks for single block ?

    component targetMode    = SelectGhashMode(TOTAL_BLOCKS);
    targetMode.foldedBlocks <== foldedBlocks;

    // S = GHASHH (A || 0^v || C || 0^u || [len(A)] || [len(C)]).
    // TODO(WJ 2024-10-23): first thing is the slectghashblock components outputs three blocks.
    component selectedBlocks = SelectGhashBlocks(TOTAL_BLOCKS);
    selectedBlocks.aad        <== aad;
    selectedBlocks.cipherText <== gctr.cipherText;
    selectedBlocks.targetMode <== targetMode.mode;

    // Step 5: Define a block, S
    component ghash = GHASHFOLDABLE();
    component cipherToStream = ToStream(1, 16);
    cipherToStream.blocks[0] <== cipherH.cipher;
    ghash.HashKey <== cipherToStream.stream;

    // TODO(WJ 2024-10-23): this is where we are folding 3 ghash blocks for some reason?
    component selectedBlocksToStream[3];
    for(var i = 0; i < 3; i++) {
        selectedBlocksToStream[i] = ToStream(1, 16);
        selectedBlocksToStream[i].blocks[0] <== selectedBlocks.blocks[i];
        ghash.msg[i] <== selectedBlocksToStream[i].stream;
    }
    ghash.lastTag <== lastTag;

    // In Steps 4 and 5, the AAD and the ciphertext are each appended with the minimum number of
    // ‘0’ bits, possibly none, so that the bit lengths of the resulting strings are multiples of the block
    // size. The concatenation of these strings is appended with the 64-bit representations of the
    // lengths of the AAD and the ciphertext, and the GHASH function is applied to the result to
    // produce a single output block.

    component selectTag = SelectGhashTag();
    selectTag.possibleTags <== ghash.possibleTags;
    selectTag.targetMode <== targetMode.mode;

    component StartJ0 = ToBlocks(16);
    for (var i = 0; i < 12; i++) {
        StartJ0.stream[i] <== iv[i];
    }
    for (var i = 12; i < 16; i++) {
        StartJ0.stream[i] <== (i == 15) ? 1 : 0;
    }

    // Step 6: Encrypt the tag. Let T = MSBt(GCTRK(J0, S))
    component gctrT = GCTR(16);
    gctrT.key <== key;
    gctrT.initialCounterBlock <== StartJ0.blocks[0];
    gctrT.plainText <== selectTag.tag;

    component m = GhashModes();
    component isEnding = Contains(2);
    isEnding.array <== [m.START_END_MODE, m.END_MODE];
    isEnding.in <== targetMode.mode;
    component useEncryption = ArraySelector(2, 16);
    useEncryption.in <== [selectTag.tag, gctrT.cipherText];
    useEncryption.index <== isEnding.out;

    authTag <== useEncryption.out;
    cipherText <== gctr.cipherText;
    // TODO: Need to fork gctr to output its counter, right now we also incr by 1.
    counter <== J0[3];
}

template GhashModes() {
    signal output START_MODE     <== 0;
    signal output START_END_MODE <== 1;
    signal output STREAM_MODE    <== 2;
    signal output END_MODE       <== 3;
}

template SelectGhashBlocks(totalBlocks) {
    signal input aad[16];
    signal input cipherText[16]; 
    signal input targetMode;
    signal output blocks[3][4][4];

    signal targetBlocks[3][3*4*4];
    signal modeToBlocks[4] <== [0, 0, 1, 2];

    component start  = GhashStartMode(totalBlocks);
    start.aad        <== aad;
    start.cipherText <== cipherText;
    targetBlocks[0]  <== start.blocks;

    component stream  = GhashStreamMode();
    stream.cipherText <== cipherText;
    targetBlocks[1]   <== stream.blocks;

    component end   = GhashEndMode(totalBlocks);
    end.cipherText  <== cipherText;
    targetBlocks[2] <== end.blocks;
    
    component mapModeToArray = Selector(4);
    mapModeToArray.in        <== modeToBlocks;
    mapModeToArray.index     <== targetMode;

    component chooseBlocks = ArraySelector(3, 3*4*4);
    chooseBlocks.in        <== targetBlocks;
    chooseBlocks.index     <== mapModeToArray.out;
    
    component toBlocks = ToBlocks(3*4*4);
    toBlocks.stream    <== chooseBlocks.out;
    blocks             <== toBlocks.blocks;
}

template SelectGhashTag() {
    signal input possibleTags[3][16];
    signal input targetMode;
    signal output tag[16];

    // Intermediate tag choosing logic
    // 
    // case 1: If we are in start_mode: Choose ghashblocks-2 (skip end tag)
    // case 2: If we are in start_end_mode: Choose ghashblocks-1 (skip none)
    // case 3: If we are in stream_mode: Choose ghashblocks-3 (first item, skip start/end)
    // case 4: If we are in end_mode: Choose ghashblocks-1 (skip start)
    
    signal modeToIndex[4] <== [2, 1, 3, 2];
    component mapModeToIndex = Selector(4);
    mapModeToIndex.in <== modeToIndex;
    mapModeToIndex.index <== targetMode;
    
    signal tagIndex <== 3 - mapModeToIndex.out;

    component s = ArraySelector(3, 16);
    s.in <== possibleTags;
    s.index <== tagIndex; 

    tag <== s.out;
}

template SelectGhashMode(totalBlocks) {
    signal input foldedBlocks;
    signal output mode;

    // May need to compute these differently due to foldedBlocks. 
    // i.e. using GT operator, Equal operator, etc. 
    signal isFinish <-- (1 >= totalBlocks-foldedBlocks) ? 1 : 0;
    signal isStart <-- (foldedBlocks == 0) ? 1: 0; 

    isFinish * (isFinish - 1) === 0;
    isStart * (isStart - 1)   === 0;

    // case isStart && isFinish: START_END_MODE
    // case isStart && !isFinish: START_MODE
    // case !isStart && !isFinish: STREAM_MODE
    // case !isStart && isFinish: END_MODE

    // Choice order is [00, 10, 01, 11]
    component m = GhashModes();
    component choice = Mux2();
    choice.c <== [m.STREAM_MODE, m.START_MODE, m.END_MODE, m.START_END_MODE];
    choice.s <== [isStart, isFinish];
    mode <== choice.out;
}

template GhashStartMode(totalBlocks) {
    signal input aad[16];
    signal input cipherText[16];
    signal output blocks[3*4*4];

    // set aad as first block (16 bytes)
    var blockIndex = 0;
    for (var i = 0; i<16; i++) {
        blocks[blockIndex] <== aad[i];
        blockIndex += 1;
    }

    // layout blocks of cipherText (l*16 bytes)
    for (var i=0; i<16; i++) {
        blocks[blockIndex] <== cipherText[i];
        blockIndex += 1;
    }

    // length of aad = 128 = 0x80 as 64 bit number (8 bytes)
    signal lengthData[8] <== [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80];
    for (var i = 0; i<8; i++) {
        blocks[blockIndex] <== lengthData[i];
        blockIndex += 1;
    }

    // length of blocks as a u64 (8 bytes)
    var len = totalBlocks * 128;
    for (var i=0; i<8; i++) {
        var byteValue = 0;
        var val = 1;
        for (var j=0; j<8; j++) {
            var bit = (len >> i*8+j) & 1;
            byteValue += bit*val;
            val = val+val;
        }
        // Insert in reversed (big endian) order. 
        blocks[blockIndex+7-i] <== byteValue;
    }
    // 16 + l + 8 + 8
    // blockIndex+=8; // TODO(CR 2024-10-18): I don't think this does anything
}

// TODO: Mildly more efficient if we add this, maybe it's needed?
template GhashStreamMode() {
    signal input cipherText[16];
    signal output blocks[48];

    var blockIndex = 0;
    // layout ciphertext (l*16 bytes)
    for (var i=0; i<16; i++) {
        blocks[blockIndex] <== cipherText[i];
        blockIndex += 1;
    }
    
    // pad remainder 
    for (var i=blockIndex; i<48; i++) {
        blocks[i] <== 0x00; 
    }
}

template GhashEndMode(totalBlocks) {
    signal input cipherText[16];
    signal output blocks[3*4*4];

    var blockIndex = 0;
    // layout ciphertext (l*16 bytes)
    for (var i=0; i<16; i++) {
        blocks[blockIndex] <== cipherText[i];
        blockIndex += 1;
    }

    signal lengthData[8] <== [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80];
    for (var i = 0; i<8; i++) {
        blocks[blockIndex] <== lengthData[i];
        blockIndex += 1;
    }

    // length of blocks as a u64 (8 bytes)
    var len = totalBlocks * 128;
    for (var i=0; i<8; i++) {
        var byte_value = 0;
        var val = 1;
        for (var j=0; j<8; j++) {
            var bit = (len >> i*8+j) & 1;
            byte_value += bit*val;
            val = val+val;
        }
        // Insert in reversed (big endian) order. 
        blocks[blockIndex+7-i] <== byte_value;
    }
    blockIndex+=8; 
    // NOTE: Added this so all of blocks is written
    for (var i = 0; i<16; i++) {
        blocks[blockIndex] <== 0;
        blockIndex += 1;
    }
}