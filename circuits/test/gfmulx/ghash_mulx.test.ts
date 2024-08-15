import chai from "chai";
import { WitnessTester } from "circomkit";
import { circomkit } from "../common";

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

    it("should compute correctly 1", async () => {
        // x^128 = x^7 + x^2 + x + 1
        let test = [1].concat(Array(127).fill(0)) // 128-bit array with MSB = 1 and everything else 0
        /// 10000111 : x^7 + x^2 + x + 1
        let expected_output: number[] = Array(120).fill(0).concat([1,0,0,0,0,1,1,1])
        await circuit.expectPass({in: test}, {out: expected_output})
    });

    it("should compute correctly 2", async () => {
        /// test vector rfc 8452 appendix A.1 https://datatracker.ietf.org/doc/html/rfc8452#appendix-A
        let bits = hexToBits("01000000000000000000000000000000")
        let expected_output = hexToBits("00800000000000000000000000000000")
        console.log(bits);
        console.log(expected_output);
        await circuit.expectPass({in: bits}, {out: expected_output})
    });
  });
});

function hexToBits(hex: string): number[] {
    // Remove the '0x' prefix if present
    if (hex.startsWith('0x')) {
      hex = hex.slice(2);
    }
  
    // Convert hex to binary string
    const binaryString = BigInt(`0x${hex}`).toString(2).padStart(hex.length * 4, '0');
  
    // Convert binary string to array of bits
    return binaryString.split('').map(bit => parseInt(bit, 10));
  }