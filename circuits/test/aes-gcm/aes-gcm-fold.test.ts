import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { circomkit, hexBytesToBigInt, hexToBytes } from "../common";

describe("aes-gcm-fold", () => {
    let circuit_one_block: WitnessTester<["key", "iv", "plainText", "aad", "step_in"], ["step_out"]>;

    it("all correct for self generated single zero pt block case", async () => {
        circuit_one_block = await circomkit.WitnessTester("aes-gcm-fold", {
            file: "aes-gcm/aes-gcm-fold",
            template: "AESGCMFOLD",
            params: [16], // input len is 16 bytes
        });

        let key       = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        let plainText = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        let iv        = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        let aad       = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        let ct        = [0x03, 0x88, 0xda, 0xce, 0x60, 0xb6, 0xa3, 0x92, 0xf3, 0x28, 0xc2, 0xb9, 0x71, 0xb2, 0xfe, 0x78];

        const counter = [0x00, 0x00, 0x00, 0x01];
        const foldedBlocks = [0x00];
        const step_in = new Array(32).fill(0x00).concat(counter).concat(foldedBlocks); 

        let expected = plainText.concat(ct).concat([0x00, 0x00, 0x00, 0x02]).concat([0x01]);

        const witness = await circuit_one_block.compute({ key: key, iv: iv, plainText: plainText, aad: aad, step_in: step_in }, ["step_out"])
        assert.deepEqual(witness.step_out, expected.map(BigInt));
    });

    it("all correct for self generated single non zero pt block", async () => {
        circuit_one_block = await circomkit.WitnessTester("aes-gcm-fold", {
            file: "aes-gcm/aes-gcm-fold",
            template: "AESGCMFOLD",
            params: [16], // input len is 16 bytes
        });

        
        let key       = [0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31];
        let plainText = [0x74, 0x65, 0x73, 0x74, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30];
        let iv        = [0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31];
        let aad       = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        let ct        = [0x29, 0x29, 0xd2, 0xbb, 0x1a, 0xe9, 0x48, 0x04, 0x40, 0x2b, 0x8e, 0x77, 0x6e, 0x0d, 0x33, 0x56];

        const counter = [0x00, 0x00, 0x00, 0x01];
        const foldedBlocks = [0x00];
        const step_in = new Array(32).fill(0x00).concat(counter).concat(foldedBlocks); 

        let expected = plainText.concat(ct).concat([0x00, 0x00, 0x00, 0x02]).concat([0x01]);

        const witness = await circuit_one_block.compute({ key: key, iv: iv, plainText: plainText, aad: aad, step_in: step_in }, ["step_out"])
        console.log(JSON.stringify(witness.step_out));
        assert.deepEqual(witness.step_out, expected.map(BigInt));
    });



//     it("all correct for self generated two block case", async () => {
//         circuit_one_block = await circomkit.WitnessTester("aes-gcm-fold", {
//             file: "aes-gcm/aes-gcm-fold",
//             template: "AESGCMFOLD",
//             params: [32], // input len is 32 bytes
//         });

//         let zero_block = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
//         let key       = [0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31];
//         let plainText1 = [0x74, 0x65, 0x73, 0x74, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30];
//         let plainText2 = [0x74, 0x65, 0x73, 0x74, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30];
//         let iv        = [0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31];
//         let aad       = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
//         let ct_part1 = [0x29, 0x29, 0xd2, 0xbb, 0x1a, 0xe9, 0x48, 0x04, 0x40, 0x2b, 0x8e, 0x77, 0x6e, 0x0d, 0x33, 0x56];
//         let ct_part2 = [0x26, 0x75, 0x65, 0x30, 0x71, 0x3e, 0x4c, 0x06, 0x5a, 0xf1, 0xd3, 0xc4, 0xf5, 0x6e, 0x02, 0x04];

//         const counter = [0x00, 0x00, 0x00, 0x01];
//         const foldedBlocks = [0x00];
//         const step_in = new Array(64).fill(0x00).concat(counter).concat(foldedBlocks); // this is correct first step. 
//         // console.log(step_in.length);

//         let expected = plainText1.concat(zero_block).concat(ct_part1).concat(zero_block).concat([0x00, 0x00, 0x00, 0x02]).concat([0x01]);
//         // console.log(expected.length);

//         const witness = await circuit_one_block.compute({ key: key, iv: iv, plainText: plainText1, aad: aad, step_in: step_in }, ["step_out"])
//         console.log(JSON.stringify(witness.step_out));
//         assert.deepEqual(witness.step_out, expected.map(BigInt));
//     });
});