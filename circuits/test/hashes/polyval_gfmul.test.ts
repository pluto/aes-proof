import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { padArrayTo64Bits, bitArrayToHex, circomkit, hexToBitArray, numberTo16Hex, numberToBitArray } from "../common";

const ZERO = hexToBitArray("0x000000000000000");
const BE_ONE = hexToBitArray("0x0000000000000001");
const MAX = hexToBitArray("0xFFFFFFFFFFFFFFFF");


describe("POLYVAL_GF_MUL", () => {
  let circuit: WitnessTester<["a", "b"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`POLYVAL_GFMUL`, {
      file: "aes-gcm/polyval_gfmul",
      template: "POLYVAL_GFMUL",
    });
  });

  // takes 5 seconds to run, leave commented
  it("POLYVAL_GF_MUL 0", async () => {
    await circuit.expectPass({ a: [MAX, MAX], b: [ZERO, ZERO] }, { out: [ZERO, ZERO] });
  });

  it("POLYVAL_GF_MUL 1", async () => {
    await circuit.expectPass({ a: [ZERO, BE_ONE], b: [ZERO, BE_ONE] }, { out: [BE_ONE, ZERO] });
  });

  it("POLYVAL_GF_MUL 2", async () => {
    const E1 = hexToBitArray("C200000000000000");
    const E2 = hexToBitArray("0000000000000001");
    await circuit.expectPass({ a: [ZERO, BE_ONE], b: [BE_ONE, ZERO] }, { out: [E1, E2] });
  });

  it("POLYVAL_GF_MUL 3", async () => {
    const E1 = hexToBitArray("0x00000000006F2B00");
    await circuit.expectPass({ a: [ZERO, hexToBitArray("0x00000000000000F1")], b: [ZERO, hexToBitArray("0x000000000000BB00")] }, { out: [E1, ZERO] });
  });

  it("POLYVAL_GF_MUL 4", async () => {
    const E1 = hexToBitArray("0x000000000043AA16");
    const f1 = hexToBitArray("0x00000000000000F1");
    const bb = hexToBitArray("0x000000000000BB00");
    await circuit.expectPass({ a: [bb, ZERO], b: [ZERO, f1] }, { out: [ZERO, E1] });
  });

  it("POLYVAL_GF_MUL 5", async () => {
    const fives = hexToBitArray("0x5555555555555555");
    const rest = hexToBitArray("0x7A01555555555555");
    await circuit.expectPass({ a: [MAX, MAX], b: [MAX, MAX] }, { out: [fives, rest] });
  });
});

describe("POLYVAL_GFMUL", () => {
  let circuit: WitnessTester<["x", "y"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`BMUL64`, {
      file: "aes-gcm/polyval_gfmul",
      template: "BMUL64",
    });
  });

  it("POLYVAL_bmul64 multiplies 1", async () => {
    const expected = "0000000000000001";
    const _res = await circuit.compute({ x: BE_ONE, y: BE_ONE }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 32);

    assert.equal(result, expected, "parse incorrect");
  });

  it("POLYVAL_bmul64 multiplies 0", async () => {
    const expected = "0000000000000000";
    const _res = await circuit.compute({ x: ZERO, y: MAX }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 32);

    assert.equal(result, expected, "parse incorrect");
  });

  it("POLYVAL_bmul64 multiplies large number", async () => {
    const X = hexToBitArray("0x1111111111111111");
    const Y = hexToBitArray("0x1111111111111111");
    const expected = "0101010101010101";
    const _res = await circuit.compute({ x: X, y: Y }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 32);

    assert.equal(result, expected, "parse incorrect");
  });

  it("POLYVAL_bmul64 multiplies large number 2", async () => {
    const X = hexToBitArray("0x1111222211118888");
    const Y = hexToBitArray("0x1111222211118888");
    const expected = "0101010140404040";
    const _res = await circuit.compute({ x: X, y: Y }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 32);

    assert.equal(result, expected, "parse incorrect");
  });

  it("POLYVAL_bmul64 multiplies large number 3", async () => {
    const X = hexToBitArray("0xCFAF222D1A198287");
    const Y = hexToBitArray("0xFBFF2C2218118182");
    const expected = "40468c9202c4418e";
    const _res = await circuit.compute({ x: X, y: Y }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 32);

    assert.equal(result, expected, "parse incorrect");
  });
});


describe("WRAPPING_BE", () => {
    let circuit: WitnessTester<["a", "b"], ["out"]>;
  
    before(async () => {
      circuit = await circomkit.WitnessTester(`WrappingMul64`, {
        file: "aes-gcm/polyval_gfmul",
        template: "WrappingMul64",
      });
    });
  
    it("wrapping mul low values", async () => {
      const a = 2;
      const a_arr = padArrayTo64Bits(numberToBitArray(a));
      for (let b = 1; b < 16; b++) {
        const expected = numberTo16Hex(a * b);
        const _res = await circuit.compute({ a: a_arr, b: hexToBitArray(numberTo16Hex(b)) }, ["out"]);
        const result = bitArrayToHex(
          (_res.out as (number | bigint)[]).map((bit) => Number(bit))
        );
  
        assert.deepEqual(result, expected, "Multiplication result is incorrect");
      }
    })
  
    it("should correctly multiply two 64-bit numbers non-overflow", async () => {
      const a = hexToBitArray("0x0000000000000002");
      const b = hexToBitArray("0x0000000000000004");
      const expected = "0000000000000008";
  
      const _res = await circuit.compute({ a, b }, ["out"]);
      const result = bitArrayToHex(
        (_res.out as (number | bigint)[]).map((bit) => Number(bit))
      );
  
      assert.deepEqual(result, expected, "Multiplication result is incorrect");
    });
  
    it("should handle multiplication with zero", async () => {
      const a = hexToBitArray("0xFFFFFFFFFFFFFFFF");
      const b = hexToBitArray("0x0000000000000000");
      const expected = "0000000000000000";
  
      const _res = await circuit.compute({ a, b }, ["out"]);
      const result = bitArrayToHex(
        (_res.out as (number | bigint)[]).map((bit) => Number(bit))
      );
  
      assert.equal(result, expected, "Multiplication with zero is incorrect");
    });
  
    it("should correctly multiply two 64-bit numbers with overflow", async () => {
      const a = hexToBitArray("0xFFFFFFFFFFFFFFFF");
      const b = hexToBitArray("0x0000000000000002");
      const expected = "fffffffffffffffe";
  
      const _res = await circuit.compute({ a, b }, ["out"]);
      const result = bitArrayToHex(
        (_res.out as (number | bigint)[]).map((bit) => Number(bit))
      );
  
      assert.deepEqual(result, expected, "Multiplication result is incorrect");
    });
  
    it("should correctly wrap on maximum overflow", async () => {
      const a = hexToBitArray("0xFFFFFFFFFFFFFFFF");
      const b = hexToBitArray("0xFFFFFFFFFFFFFFFF");
      const expected = "0000000000000001";
  
      const _res = await circuit.compute({ a, b }, ["out"]);
      const result = bitArrayToHex(
        (_res.out as (number | bigint)[]).map((bit) => Number(bit))
      );
  
      assert.equal(result, expected, "Wrap-around on overflow is incorrect");
    });
  
    it("should correctly wrap on maximum overflow", async () => {
      const a = hexToBitArray("0xFFFFFFFFFFFFFFFF");
      const b = hexToBitArray("0xFFFFFFFFFFFFFFFF");
      const expected = "0000000000000001";
  
      const _res = await circuit.compute({ a, b }, ["out"]);
      const result = bitArrayToHex(
        (_res.out as (number | bigint)[]).map((bit) => Number(bit))
      );
  
      assert.equal(result, expected, "Wrap-around on overflow is incorrect");
    });
  
    it("should correctly wrap on large numbers below max", async () => {
      const a = hexToBitArray("0xa5a5a5a5a5a5a5a5");
      const b = hexToBitArray("0x5a5a5a5a5a5a5a5a");
      const expected = "a76b2ef2b67a3e02";
  
      const _res = await circuit.compute({ a, b }, ["out"]);
      const result = bitArrayToHex(
        (_res.out as (number | bigint)[]).map((bit) => Number(bit))
      );
  
      assert.equal(result, expected, "Wrap-around on overflow is incorrect");
    });
  
    it("should correctly multiply this one particular case", async () => {
      const a = hexToBitArray("0x0000000000008888");
      const b = hexToBitArray("0x0000000000008888");
      const expected = "0000000048d0c840";
  
      const _res = await circuit.compute({ a, b }, ["out"]);
      const result = bitArrayToHex(
        (_res.out as (number | bigint)[]).map((bit) => Number(bit))
      );
  
      assert.equal(result, expected, "Wrap-around on overflow is incorrect");
    });
  });
  