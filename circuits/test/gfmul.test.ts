import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { padArrayTo64Bits, bitArrayToHex, circomkit, hexToBitArray, numberTo16Hex, numberToBitArray } from "./common";

const X = hexToBitArray("0x0100000000000000");
const Y = hexToBitArray("0x0100000000000000");
const EXPECT = "";

describe("BMUL64", () => {
  let circuit: WitnessTester<["x", "y"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`BMUL64`, {
      file: "aes-gcm/gfmul",
      template: "BMUL64",
      // params: [8],
    });
  });

  // let bit_array = [1,0,0,0,0,0,0,0];
  // let expected_output = [0,0,0,0,0,0,0,1].map((x) => BigInt(x));
  it("bmul64", async () => {
    const _res = await circuit.compute({ x: X, y: Y }, ["out"]);
    // const result = bitArrayToHex(
    //   (_res.out as number[]).map((bit) => Number(bit))
    // ).slice(0, 32);
    // console.log("expect: ", EXPECT, "\nresult: ", result);
    // assert.equal(result, EXPECT);
  });
});

describe("MUL", () => {
  let circuit: WitnessTester<["h", "rhs"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`MUL64`, {
      file: "aes-gcm/gfmul",
      template: "MUL",
      // params: [8],
    });
  });

  // let bit_array = [1,0,0,0,0,0,0,0];
  // let expected_output = [0,0,0,0,0,0,0,1].map((x) => BigInt(x));
  it("mul", async () => {
    const _res = await circuit.compute({ h: X, rhs: Y }, ["out"]);
    // const result = bitArrayToHex(
    //   (_res.out as number[]).map((bit) => Number(bit))
    // ).slice(0, 32);
    // console.log("expect: ", EXPECT, "\nresult: ", result);
    // assert.equal(result, EXPECT);
  });
});

describe("WRAPPING_BE", () => {
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
