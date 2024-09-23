import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { circomkit, hexBytesToBigInt, hexToBytes } from "../common";

describe("aes-gcm-fold", () => {
    it("should work for self generated test case", async () => {
        let circuit_one_block: WitnessTester<["key", "iv", "plainText", "aad", "step_in"], ["cipherText", "tag", "step_out"]>;
        circuit_one_block = await circomkit.WitnessTester("aes-gcm-fold", {
            file: "aes-gcm/aes-gcm-fold",
            template: "AESGCMFOLD",
            // ciphertext bytes, total bytes => i.e. one fold.
            params: [16, 16],
        });

        const key = hexToBytes('31313131313131313131313131313131');
        const iv = hexToBytes('313131313131313131313131');
        const msg = hexToBytes('7465737468656c6c6f30303030303030');
        const aad = hexToBytes('00000000000000000000000000000000')
        const ct = hexToBytes('2929d2bb1ae94804402b8e776e0d3356');

        // TODO: Make this match. 
        const auth_tag = hexToBytes('0cab39e1a491b092185965f7b554aea0');

        const counter = [0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x01];
        const startTag = [0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00];
        const foldedBlocks = [0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00];
        const step_in = [counter, startTag, foldedBlocks];

        const witness = await circuit_one_block.compute({ key: key, iv: iv, plainText: msg, aad: aad, step_in: step_in }, ["cipherText", "authTag", "step_out"])
        assert.deepEqual(witness.cipherText, hexBytesToBigInt(ct))

        console.log("step out", witness.step_out);
    });
});