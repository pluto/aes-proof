import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { padArrayTo64Bits, bitArrayToHex, circomkit, hexToBitArray, numberTo16Hex, numberToBitArray } from "../common";

describe("WRAPPING_BE", () => {
  let circuit: WitnessTester<["a", "b"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`WrappingMul64`, {
      file: "aes-gcm/wrapping_mul",
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
