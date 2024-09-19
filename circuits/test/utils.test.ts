import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { circomkit, hexBytesToBigInt, hexToBytes } from "./common";

describe("utils", () => {
    it("test array selector", async () => {
        let circuit: WitnessTester<["in", "index"], ["out"]>;
        circuit = await circomkit.WitnessTester(`ArraySelector`, {
        file: "aes-gcm/utils",
        template: "ArraySelector",
        params: [3,4],
        });

        let selector = 1;
        let selections = [
            [0x0,0x0,0x0,0x01],
            [0x06,0x07,0x08,0x09],
            [0x0,0x0,0x0,0x03],
        ]
        let selected = [0x06,0x07,0x08,0x09].map(BigInt);
        console.log("selections", selections);
        const witness = await circuit.compute({in: selections, index: selector}, ["out"])
        console.log("selected", witness.out);
        assert.deepEqual(witness.out, selected)
    });

    it("test selector", async () => {
        let circuit: WitnessTester<["in", "index"], ["out"]>;
        circuit = await circomkit.WitnessTester(`Selector`, {
        file: "aes-gcm/utils",
        template: "Selector",
        params: [4],
        });

        let selector = 2;
        let selections = [0x0,0x0,0x08,0x01];
        console.log("selections", selections);
        const witness = await circuit.compute({in: selections, index: selector}, ["out"])
        console.log("selected", witness.out);
        assert.deepEqual(witness.out, BigInt(0x08))
    });
});