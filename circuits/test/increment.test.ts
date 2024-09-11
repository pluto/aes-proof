import { WitnessTester } from "circomkit";
import { circomkit } from "./common";

describe("IncrementWord", () => {
    let circuit: WitnessTester<["in"], ["out"]>;
    it("should increment the word input", async () => {
        circuit = await circomkit.WitnessTester(`IncrementByte`, {
            file: "aes-gcm/utils",
            template: "IncrementWord",
        });
        await circuit.expectPass(
            {
                in: [0x00, 0x00, 0x00, 0x00],
            },
            {
                out: [0x00, 0x00, 0x00, 0x01],
            }
        );

    });
    it("should increment the word input on overflow", async () => {
        circuit = await circomkit.WitnessTester(`IncrementWord`, {
            file: "aes-gcm/utils",
            template: "IncrementWord",
        });
        await circuit.expectPass(
            {
                in: [0x00, 0x00, 0x00, 0xFF],
            },
            {
                out: [0x00, 0x00, 0x01, 0x00],
            }
        );
    });
    it("should increment the word input on overflow", async () => {
        circuit = await circomkit.WitnessTester(`IncrementWord`, {
            file: "aes-gcm/utils",
            template: "IncrementWord",
        });
        await circuit.expectPass(
            {
                in: [0xFF, 0xFF, 0xFF, 0xFF],
            },
            {
                out: [0x00, 0x00, 0x00, 0x00],
            }
        );
    });
});

describe("IncrementByte", () => {
    let circuit: WitnessTester<["in"], ["out"]>;
    it("should increment the byte input", async () => {
        circuit = await circomkit.WitnessTester(`IncrementByte`, {
            file: "aes-gcm/utils",
            template: "IncrementByte",
        });
        await circuit.expectPass(
            {
                in: 0x00,
            },
            {
                out: 0x01,
            }
        );
    });

    it("should increment the byte input on overflow", async () => {
        circuit = await circomkit.WitnessTester(`IncrementByte`, {
            file: "aes-gcm/utils",
            template: "IncrementByte",
        });
        await circuit.expectPass(
            {
                in: 0xFF,
            },
            {
                out: 0x00,
            }
        );
    });
});