import chai from "chai";
import { WitnessTester } from "circomkit";
import { circomkit } from "./common";

// Disable truncation of arrays in error messages
chai.config.truncateThreshold = 0;

describe("GFMulX", () => {
  let circuit: WitnessTester<["in"], ["out"]>;

  describe("GF Mul X test", () => {
    before(async () => {
      circuit = await circomkit.WitnessTester(`gfmulx`, {
        file: "aes-gcm/gfmulx",
        template: "GFMULX",
      });
      console.log("#constraints:", await circuit.getConstraintCount());
    });

    // x^8 + x^4 + x^3 + x + 1
    it("should compute correctly 1", async () => {
        // x^128 = x^7 + x^2 + x + 1
        let test = [1].concat(Array(127).fill(0)) // 128-bit array with MSB = 1 and everything else 0
        /// 10000111
        let expected_output: number[] = Array(120).fill(0).concat([1,0,0,0,0,1,1,1])
        await circuit.expectPass({in: test}, {out: expected_output})
    });
  });
});