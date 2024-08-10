import { WitnessTester } from "circomkit";
import { circomkit } from "./common";

describe("AES Emulation", () => {
    let circuit: WitnessTester<["in"], ["out"]>;

    before(async () => {
        circuit = await circomkit.WitnessTester(`RowShifting`, {
            file: "aes-gcm/aes_emulation",
            template: "EmulatedAesencRowShifting",
        });
        console.log("#constraints:", await circuit.getConstraintCount());
    });

    // TODO: Do we actually understand this?
    it("should have correct number of constraints", async () => {
        await circuit.expectConstraintCount(16, true); /// should fail
    });

    const zeroArray: number[] = new Array(16).fill(0);

    it("witness: in = [0,...]", async () => {
        await circuit.expectPass(
            { in: zeroArray },
            { out: zeroArray }
        );
    });

    const indexArray: number[] = Array.from({ length: 16 }, (_, index) => index);
    // State([[0, 5, 10, 15], [4, 9, 14, 3], [8, 13, 2, 7], [12, 1, 6, 11]])
    const outArray: number[] = [0, 5, 10, 15, 4, 9, 14, 3, 8, 13, 2, 7, 12, 1, 6, 11];
    it("witness: in = [0,1,2,3,...,15]", async () => {
        await circuit.expectPass(
            { in: indexArray },
            { out: outArray }
        );
    });
});