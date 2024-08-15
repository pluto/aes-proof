import chai, { assert, expect } from "chai";
import { WitnessTester } from "circomkit";
import { circomkit } from "../common";

// Disable truncation of arrays in error messages
chai.config.truncateThreshold = 0;

const mulXTestVectors = [
  "02000000000000000000000000000000",
  "04000000000000000000000000000000",
  "08000000000000000000000000000000",
  "10000000000000000000000000000000",
  "20000000000000000000000000000000",
  "40000000000000000000000000000000",
  "80000000000000000000000000000000",
  "00010000000000000000000000000000",
  // "00020000000000000000000000000000",
  // "00040000000000000000000000000000",
  // "00080000000000000000000000000000",
  // "00100000000000000000000000000000",
  // "00200000000000000000000000000000",
  // "00400000000000000000000000000000",
  // "00800000000000000000000000000000",
  // "00000100000000000000000000000000",
  // "00000200000000000000000000000000",
  // "00000400000000000000000000000000",
  // "00000800000000000000000000000000",
  // "00001000000000000000000000000000",
  // "00002000000000000000000000000000",
  // "00004000000000000000000000000000",
  // "00008000000000000000000000000000",
  // "00000001000000000000000000000000",
  // "00000002000000000000000000000000",
  // "00000004000000000000000000000000",
  // "00000008000000000000000000000000",
  // "00000010000000000000000000000000",
  // "00000020000000000000000000000000",
  // "00000040000000000000000000000000",
  // "00000080000000000000000000000000",
  // "00000000010000000000000000000000",
  // "00000000020000000000000000000000",
  // "00000000040000000000000000000000",
  // "00000000080000000000000000000000",
  // "00000000100000000000000000000000",
  // "00000000200000000000000000000000",
  // "00000000400000000000000000000000",
  // "00000000800000000000000000000000",
  // "00000000000100000000000000000000",
  // "00000000000200000000000000000000",
  // "00000000000400000000000000000000",
  // "00000000000800000000000000000000",
  // "00000000001000000000000000000000",
  // "00000000002000000000000000000000",
  // "00000000004000000000000000000000",
  // "00000000008000000000000000000000",
  // "00000000000001000000000000000000",
  // "00000000000002000000000000000000",
  // "00000000000004000000000000000000",
  // "00000000000008000000000000000000",
  // "00000000000010000000000000000000",
  // "00000000000020000000000000000000",
  // "00000000000040000000000000000000",
  // "00000000000080000000000000000000",
  // "00000000000000010000000000000000",
  // "00000000000000020000000000000000",
  // "00000000000000040000000000000000",
  // "00000000000000080000000000000000",
  // "00000000000000100000000000000000",
  // "00000000000000200000000000000000",
  // "00000000000000400000000000000000",
  // "00000000000000800000000000000000",
  // "00000000000000000100000000000000",
  // "00000000000000000200000000000000",
  // "00000000000000000400000000000000",
  // "00000000000000000800000000000000",
  // "00000000000000001000000000000000",
  // "00000000000000002000000000000000",
  // "00000000000000004000000000000000",
  // "00000000000000008000000000000000",
  // "00000000000000000001000000000000",
  // "00000000000000000002000000000000",
  // "00000000000000000004000000000000",
  // "00000000000000000008000000000000",
  // "00000000000000000010000000000000",
  // "00000000000000000020000000000000",
  // "00000000000000000040000000000000",
  // "00000000000000000080000000000000",
  // "00000000000000000000010000000000",
  // "00000000000000000000020000000000",
  // "00000000000000000000040000000000",
  // "00000000000000000000080000000000",
  // "00000000000000000000100000000000",
  // "00000000000000000000200000000000",
  // "00000000000000000000400000000000",
  // "00000000000000000000800000000000",
  // "00000000000000000000000100000000",
  // "00000000000000000000000200000000",
  // "00000000000000000000000400000000",
  // "00000000000000000000000800000000",
  // "00000000000000000000001000000000",
  // "00000000000000000000002000000000",
  // "00000000000000000000004000000000",
  // "00000000000000000000008000000000",
  // "00000000000000000000000001000000",
  // "00000000000000000000000002000000",
  // "00000000000000000000000004000000",
  // "00000000000000000000000008000000",
  // "00000000000000000000000010000000",
  // "00000000000000000000000020000000",
  // "00000000000000000000000040000000",
  // "00000000000000000000000080000000",
  // "00000000000000000000000000010000",
  // "00000000000000000000000000020000",
  // "00000000000000000000000000040000",
  // "00000000000000000000000000080000",
  // "00000000000000000000000000100000",
  // "00000000000000000000000000200000",
  // "00000000000000000000000000400000",
  // "00000000000000000000000000800000",
  // "00000000000000000000000000000100",
  // "00000000000000000000000000000200",
  // "00000000000000000000000000000400",
  // "00000000000000000000000000000800",
  // "00000000000000000000000000001000",
  // "00000000000000000000000000002000",
  // "00000000000000000000000000004000",
  // "00000000000000000000000000008000",
  // "00000000000000000000000000000001",
  // "00000000000000000000000000000002",
  // "00000000000000000000000000000004",
  // "00000000000000000000000000000008",
  // "00000000000000000000000000000010",
  // "00000000000000000000000000000020",
  // "00000000000000000000000000000040",
  // "00000000000000000000000000000080",
  // "010000000000000000000000000000c2",
];

// polyval irreducible polynomial: x^128 + x^127 + x^126 + x^121 + 1
// note that polyval uses LE encoding.
const polyvalIrreduciblePolynomial: number[] = Array(120)
  .fill(0)
  .concat([1, 0, 0, 0, 0, 1, 1, 1])
  .reverse();

describe("polyval_GFMulX", () => {
  let circuit: WitnessTester<["in"], ["out"]>;

  describe("polyval GF Mul X test", () => {
    before(async () => {
      circuit = await circomkit.WitnessTester(`gfmulx`, {
        file: "aes-gcm/gfmulx",
        template: "polyval_GFMULX",
      });
      console.log("#constraints:", await circuit.getConstraintCount());
    });

    it("test polyval at all bits set", async () => {
      let bits = hexToBitArray("01000000000000000000000000000000");
      // for (vector in mulXTestVectors) {
      for (let i = 0; i < mulXTestVectors.length; i++) {
        const expect = mulXTestVectors[i];
        const _res = await circuit.compute({ in: bits }, ["out"]);
        const result = bitArrayToHex(
          (_res.out as (number | bigint)[]).map((bit) => Number(bit))
        );
        console.log("expect: ", expect, "\nresult: ", result);
        assert.equal(expect, result);
        bits = hexToBitArray(result);
      }
    });

    // // ref: https://datatracker.ietf.org/doc/html/rfc8452#appendix-A
    // it("compute IETF test 2", async () => {
    //   let bits = hexToBitArray("9c98c04df9387ded828175a92ba652d8");
    //   let expected_output = hexToBitArray("3931819bf271fada0503eb52574ca5f2");
    //   // console.log(bits);
    //   // console.log(expected_output);
    //   await circuit.expectPass({ in: bits }, { out: expected_output });
    // });

    it("tests hexToBitArray", async () => {
      let hex = "0F";
      let expectedBits = [0, 0, 0, 0, 1, 1, 1, 1];
      let result = hexToBitArray(hex);
      assert.deepEqual(result, expectedBits);

      hex = "1248";
      expectedBits = [0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0];
      result = hexToBitArray(hex);
      assert.deepEqual(result, expectedBits);
    });

    it("tests bitArrayToHexString", async () => {
      let bits = [0, 0, 0, 0, 1, 1, 1, 1];
      let expectedHex = "0f";
      let result = bitArrayToHex(bits);
      assert.equal(result, expectedHex);

      bits = [1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1];
      expectedHex = "8b09";
      result = bitArrayToHex(bits);
      assert.equal(result, expectedHex);
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

function bitArrayToHex(bits: number[]): string {
  // console.log(bits);
  if (bits.length % 8 !== 0) {
    throw new Error("Input length must be a multiple of 8 bits");
  }

  return bits
    .reduce((acc, bit, index) => {
      const byteIndex = Math.floor(index / 8);
      const bitPosition = 7 - (index % 8);
      acc[byteIndex] = (acc[byteIndex] || 0) | (bit << bitPosition);
      return acc;
    }, new Array(bits.length / 8).fill(0))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

describe("LeftShiftLE", () => {
  const shift_1 = 1;
  const shift_2 = 2;
  let circuit: WitnessTester<["in"], ["out"]>;

  describe("leftshiftLE", () => {
    before(async () => {
      circuit = await circomkit.WitnessTester(`LeftShiftLE`, {
        file: "aes-gcm/gfmulx",
        template: "LeftShiftLE",
        params: [shift_1],
      });
    });

    it("tests leftshiftLE", async () => {
      let bits = [1].concat(Array(127).fill(0));
      let expect = Array(15).fill(0).concat([1]).concat(Array(112).fill(0));
      let _res = await circuit.compute({ in: bits }, ["out"]);
      let result = (_res.out as (number | bigint)[]).map((bit) => Number(bit));
      assert.deepEqual(result, expect);

      bits = [0, 1].concat(Array(126).fill(0));
      expect = [1].concat(Array(127).fill(0));
      _res = await circuit.compute({ in: bits }, ["out"]);
      result = (_res.out as (number | bigint)[]).map((bit) => Number(bit));
      assert.deepEqual(result, expect);
    });
  });

  describe("leftshiftLE shift 2", () => {
    before(async () => {
      circuit = await circomkit.WitnessTester(`LeftShiftLE`, {
        file: "aes-gcm/gfmulx",
        template: "LeftShiftLE",
        params: [shift_2],
      });
    });

    it("tests leftshiftLE", async () => {
      let bits = [1].concat(Array(127).fill(0));
      let expect = Array(14).fill(0).concat([1]).concat(Array(113).fill(0));
      let _res = await circuit.compute({ in: bits }, ["out"]);
      let result = (_res.out as (number | bigint)[]).map((bit) => Number(bit));
      assert.deepEqual(result, expect);
    });
  });
});
