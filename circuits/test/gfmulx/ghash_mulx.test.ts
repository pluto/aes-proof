import chai, { assert, expect } from "chai";
import { WitnessTester } from "circomkit";
import { circomkit } from "../common";

// Disable truncation of arrays in error messages
chai.config.truncateThreshold = 0;

// ghash irreducible polynomial: x^128 = x^7 + x^2 + x + 1
const ghashIrreduciblePolynomial: number[] = Array(120)
  .fill(0)
  .concat([1, 0, 0, 0, 0, 1, 1, 1]);

describe("ghash_GFMulX", () => {
  let circuit: WitnessTester<["in"], ["out"]>;

  describe("ghash GF Mul X test", () => {
    before(async () => {
      circuit = await circomkit.WitnessTester(`gfmulx`, {
        file: "aes-gcm/gfmulx",
        template: "ghash_GFMULX",
      });
      console.log("#constraints:", await circuit.getConstraintCount());
    });

    it("send 1000... to the irreducible polynomial", async () => {
      const test = [1].concat(Array(127).fill(0));
      await circuit.expectPass(
        { in: test },
        { out: ghashIrreduciblePolynomial }
      );
    });

    // ref: https://datatracker.ietf.org/doc/html/rfc8452#appendix-A
    // todo
    it("compute IETF test 1: expect 2", async () => {
      let bits = hexToBitArray("01000000000000000000000000000000");
      let expected = hexToBitArray("00800000000000000000000000000000");
      // let expected = [0,0,8].concat(Array(29).fill(0))
      // console.log(bits);
      // console.log(expected);
      await circuit.expectPass({ in: bits }, { out: expected });
    });

    // ref: https://datatracker.ietf.org/doc/html/rfc8452#appendix-A
    it("compute IETF test 2", async () => {
      let bits = hexToBitArray("9c98c04df9387ded828175a92ba652d8");
      let expected_output = hexToBitArray("4e4c6026fc9c3ef6c140bad495d3296c");
      // console.log(bits);
      // console.log(expected_output);
      await circuit.expectPass({ in: bits }, { out: expected_output });
    });

    it("tests hexToBitArray", async () => {
      let hex = "0F";
      let expectedBits = [0, 0, 0, 0, 1, 1, 1, 1];
      let result = hexToBitArray(hex);
      result.forEach((bit, index) => {
        expect(bit).equals(expectedBits[index]);
      });

      hex = "1248";
      expectedBits = [0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0];
      result = hexToBitArray(hex);
      result.forEach((bit, index) => {
        expect(bit).equals(expectedBits[index]);
      });
    });
  });
});

function hexToBitArray(hex: string): number[] {
  // Remove '0x' prefix if present and ensure lowercase
  hex = hex.replace(/^0x/i, "").toLowerCase();

  // Ensure even number of characters
  if (hex.length % 2 !== 0) {
    hex = "0" + hex;
  }

  return (
    hex
      // Split into pairs of characters
      .match(/.{2}/g)!
      .flatMap((pair) => {
        const byte = parseInt(pair, 16);
        // map byte to 8-bits. Apologies for the obtuse mapping;
        // which cycles through the bits in byte and extracts them one by one.
        return Array.from({ length: 8 }, (_, i) => (byte >> (7 - i)) & 1);
      })
  );
}
