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
        const authTag = hexToBytes('9a636f50dc842820c798d001d9a9c4bd');

        const counter = [0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x01];
        const startTag = [0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00];
        const foldedBlocks = [0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00];
        const step_in = [counter, startTag, foldedBlocks];

        const witness = await circuit_one_block.compute({ key: key, iv: iv, plainText: msg, aad: aad, step_in: step_in }, ["cipherText", "authTag", "step_out"])
        assert.deepEqual(witness.cipherText, hexBytesToBigInt(ct));
        assert.deepEqual((witness.step_out as BigInt[]).slice(16, 32), hexBytesToBigInt(authTag));
    });

    // TODO:
    // Test for each mode, start, start_end, stream, end
});