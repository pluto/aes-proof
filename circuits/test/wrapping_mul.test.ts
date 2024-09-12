import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { padArrayTo64Bits, bitArrayToHex, circomkit, hexToBitArray, numberTo16Hex, numberToBitArray } from "./common";

describe("WRAPPING_LE", () => {
  let circuit: WitnessTester<["a", "b"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`WrappingMul64`, {
      file: "aes-gcm/mul",
      template: "WrappingMul64",
    });
  });

  it("wrapping mul low values", async () => {
    const a = 2;
    const a_arr = padArrayTo64Bits(numberToBitArray(a));
    for (var b = 1; b < 16; b++) {
      const expected = numberTo16Hex(a * b);
      const _res = await circuit.compute({ a: a_arr, b: hexToBitArray(numberTo16Hex(b)) }, ["out"]);
      const result = bitArrayToHex(
        (_res.out as (number | bigint)[]).map((bit) => Number(bit))
      );

      assert.deepEqual(result, expected, "Multiplication result is incorrect");
    }
  })

  // todo: choose a better test case, the expected value is wrong
  it("should correctly multiply two 64-bit numbers non-overflow", async () => {
    const a = hexToBitArray("0x0000000000000002");
    const b = hexToBitArray("0x0000000000000004");
    const expected = "0000000000000008";

    // await circuit.expectPass({ a, b }, { out: hexToBitArray(expected) });

    // const _res = await circuit.calculateWitness({ a, b });
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

  // todo: choose a better test case, the expected value is wrong
  it("should correctly multiply two 64-bit numbers with overflow", async () => {
    const a = hexToBitArray("0xFFFFFFFFFFFFFFFF");
    const b = hexToBitArray("0x0000000000000002");
    const expected = "fffffffffffffffe";

    // await circuit.expectPass({ a, b }, { out: hexToBitArray(expected) });

    // const _res = await circuit.calculateWitness({ a, b });
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
});
