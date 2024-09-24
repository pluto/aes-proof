import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { circomkit, hexBytesToBigInt, hexToBytes } from "../common";

describe("aes-gcm-fold", () => {
    const shared_witness = {
        key: hexToBytes('31313131313131313131313131313131'),
        iv: hexToBytes('313131313131313131313131'),
        plainText: hexToBytes('7465737468656c6c6f30303030303030'),
        aad: hexToBytes('00000000000000000000000000000000'),
    };

    it("all correct for self generated single block case", async () => {
        let circuit_one_block: WitnessTester<["key", "iv", "plainText", "aad", "step_in"], ["cipherText", "tag", "step_out"]>;
        circuit_one_block = await circomkit.WitnessTester("aes-gcm-fold", {
            file: "aes-gcm/aes-gcm-fold",
            template: "AESGCMFOLD",
            // ciphertext bytes, total bytes => i.e. one fold.
            params: [16, 16],
        });

        const ct = hexToBytes('2929d2bb1ae94804402b8e776e0d3356');
        const authTag = hexToBytes('9a636f50dc842820c798d001d9a9c4bd');

        const counter = [0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x01];
        const startTag = [0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00];
        const foldedBlocks = [0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00];
        const step_in = [counter, startTag, foldedBlocks];

        const witness = await circuit_one_block.compute({ ...shared_witness, step_in: step_in }, ["cipherText", "authTag", "step_out"])
        assert.deepEqual(witness.cipherText, hexBytesToBigInt(ct));
        assert.deepEqual((witness.step_out as BigInt[]).slice(16, 32), hexBytesToBigInt(authTag));
    });
    
    it("outputs correct tag in start mode", async () => {
        let circuit_one_block: WitnessTester<["key", "iv", "plainText", "aad", "step_in"], ["cipherText", "tag", "step_out"]>;
        circuit_one_block = await circomkit.WitnessTester("aes-gcm-fold", {
            file: "aes-gcm/aes-gcm-fold",
            template: "AESGCMFOLD",
            // ciphertext bytes, total bytes => first fold, but many folds to do.
            params: [16, 48],
        });

        // NOTE: We use the same plaintext, but expect a different ct because the counter has increased.
        const ct = hexToBytes('2929d2bb1ae94804402b8e776e0d3356');
        const expectedTag = hexToBytes('0b1fb4f1762e2f93f521e3f5acab2e03');
        const counter = [0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x01];
        const startTag = [0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00];
        const foldedBlocks = [0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00];
        const step_in = [counter, startTag, foldedBlocks];

        const witness = await circuit_one_block.compute({ ...shared_witness, step_in: step_in }, ["cipherText", "authTag", "step_out"])
        const intermediateTag = (witness.step_out as BigInt[]).slice(16, 32);
        console.log("intermediate tag", intermediateTag);
        assert.deepEqual(witness.cipherText, hexBytesToBigInt(ct));
        assert.deepEqual(intermediateTag, hexBytesToBigInt(expectedTag));
    });

    it("outputs correct tag in stream mode", async () => {
        let circuit_one_block: WitnessTester<["key", "iv", "plainText", "aad", "step_in"], ["cipherText", "tag", "step_out"]>;
        circuit_one_block = await circomkit.WitnessTester("aes-gcm-fold", {
            file: "aes-gcm/aes-gcm-fold",
            template: "AESGCMFOLD",
            // ciphertext bytes, total bytes => first fold, but many folds to do.
            params: [16, 48],
        });

        const ct = hexToBytes('26756530713e4c065af1d3c4f56e0204');
        const expectedTag = hexToBytes('116057c3018743e61233919efb60c62c');

        const counter = [0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x02];
        const startTag = [0x0b,0x1f,0xb4,0xf1, 0x76,0x2e,0x2f,0x93, 0xf5,0x21,0xe3,0xf5, 0xac,0xab,0x2e,0x03];
        const foldedBlocks = [0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x01];
        const step_in = [counter, startTag, foldedBlocks];

        const witness = await circuit_one_block.compute({ ...shared_witness, step_in: step_in }, ["cipherText", "authTag", "step_out"])
        const intermediateTag = (witness.step_out as BigInt[]).slice(16, 32);
        console.log("intermediate tag", intermediateTag);
        assert.deepEqual(witness.cipherText, hexBytesToBigInt(ct));
        assert.deepEqual(intermediateTag, hexBytesToBigInt(expectedTag));
    });
    
    // Finally, we are on the end fold. Check the correct tag and cipher based on the intermediate stages.
    it("outputs correct tag in end mode", async () => {
        let circuit_one_block: WitnessTester<["key", "iv", "plainText", "aad", "step_in"], ["cipherText", "tag", "step_out"]>;
        circuit_one_block = await circomkit.WitnessTester("aes-gcm-fold", {
            file: "aes-gcm/aes-gcm-fold",
            template: "AESGCMFOLD",
            // ciphertext bytes, total bytes => first fold, but many folds to do.
            params: [16, 48],
        });

        const ct = hexToBytes('36854c327ec16e03d895c3ff8c007654');
        const expectedTag = hexToBytes('4a1722a2ad1673c17c057cd9a886e33d');
        const counter = [0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x03];
        const startTag = [0x11,0x60,0x57,0xc3,0x01,0x87,0x43,0xe6,0x12,0x33,0x91,0x9e,0xfb,0x60,0xc6,0x2c];
        const foldedBlocks = [0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x02];
        const step_in = [counter, startTag, foldedBlocks];

        const witness = await circuit_one_block.compute({ ...shared_witness, step_in: step_in }, ["cipherText", "authTag", "step_out"])
        const intermediateTag = (witness.step_out as BigInt[]).slice(16, 32);
        assert.deepEqual(witness.cipherText, hexBytesToBigInt(ct));
        assert.deepEqual(intermediateTag, hexBytesToBigInt(expectedTag));
    });
});