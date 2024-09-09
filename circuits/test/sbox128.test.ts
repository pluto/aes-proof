import { WitnessTester } from "circomkit";
import { circomkit } from "./common";

describe("SBox128", () => {
  let circuit: WitnessTester<["in"], ["out"]>;

  describe("SubBox", () => {
    before(async () => {
      circuit = await circomkit.WitnessTester(`SubBytes`, {
        file: "aes-ctr/sbox128",
        template: "SBox128",
      });
      console.log("#constraints:", await circuit.getConstraintCount());
    });

    it("should compute correctly", async () => {
      await circuit.expectPass({ in: 0x53 }, { out: 0xed });
      await circuit.expectPass({ in: 0x00 }, { out: 0x63 });
    });
  });


  describe("InvSBox128", () => {
    before(async () => {
      circuit = await circomkit.WitnessTester(`InvSubBytes`, {
        file: "aes-ctr/sbox128",
        template: "InvSBox128",
      });
      console.log("#constraints:", await circuit.getConstraintCount());
    });

    it("should compute correctly", async () => {
      await circuit.expectPass({ in: 0xed }, { out: 0x53 });
      await circuit.expectPass({ in: 0x63 }, { out: 0x00 });
    });
  });
});
