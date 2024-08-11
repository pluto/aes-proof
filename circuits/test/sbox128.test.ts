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
});
