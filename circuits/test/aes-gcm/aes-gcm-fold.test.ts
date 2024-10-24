import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { circomkit, hexBytesToBigInt, hexToBytes } from "../common";

describe("aes-gcm-fold", () => {
    let circuit_one_block: WitnessTester<["key", "iv", "plainText", "aad", "step_in"], ["step_out"]>;

    // const shared_witness = {
    //     key: hexToBytes('31313131313131313131313131313131'),
    //     iv: hexToBytes('313131313131313131313131'),
    //     plainText: hexToBytes('7465737468656c6c6f30303030303030'),
    //     aad: hexToBytes('00000000000000000000000000000000'),
    // };

    it("all correct for self generated single block case", async () => {
        circuit_one_block = await circomkit.WitnessTester("aes-gcm-fold", {
            file: "aes-gcm/aes-gcm-fold",
            template: "AESGCMFOLD",
            params: [16], // input len is 16 bytes
        });
        console.log("#constraints:", await circuit_one_block.getConstraintCount());


        // step_in[0..INPUT_LEN] => accumulate plaintext blocks
        // step_in[INPUT_LEN..INPUT_LEN*2]  => accumulate ciphertext blocks
        // TODO(WJ 2024-10-24): Are the counter and folded blocks the same? Maybe it is redundant.
        // step_in[INPUT_LEN*2..INPUT_LEN*2+4]  => lastCounter
        // step_in[INPUT_LEN*2+5]     => foldedBlocks
        // first block (16bytes) is the plaintext
        let key       = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        let plainText = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        let iv        = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        let aad       = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        let ct        = [0x03, 0x88, 0xda, 0xce, 0x60, 0xb6, 0xa3, 0x92, 0xf3, 0x28, 0xc2, 0xb9, 0x71, 0xb2, 0xfe, 0x78];

        const counter = [0x00, 0x00, 0x00, 0x00];
        const foldedBlocks = [0x00];
        const step_in = plainText.concat(plainText).concat(counter).concat(foldedBlocks);
        console.log("step in before",step_in);

        let expected = plainText.concat(ct).concat(counter).concat(foldedBlocks);


        const witness = await circuit_one_block.compute({ key: key, iv: iv, plainText: plainText, aad: aad, step_in: step_in }, ["step_out"])
        console.log("witness.step_out", witness.step_out);
        assert.deepEqual(witness.step_out, expected.map(BigInt));
    });
});