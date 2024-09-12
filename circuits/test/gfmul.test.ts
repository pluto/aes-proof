import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { padArrayTo64Bits, bitArrayToHex, circomkit, hexToBitArray, numberTo16Hex, numberToBitArray } from "./common";

describe("BMUL64", () => {
  let circuit: WitnessTester<["x", "y"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`BMUL64`, {
      file: "aes-gcm/gfmul",
      template: "BMUL64",
    });
  });

  it("bmul64 multiplies 1", async () => {
    const X = hexToBitArray("0x0000000000000001");
    const Y = hexToBitArray("0x0000000000000001");
    const expected = "0000000000000001";
    const _res = await circuit.compute({ x: X, y: Y }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 32);

    assert.equal(result, expected, "parse incorrect");
  });

  it("bmul64 multiplies 0", async () => {
    const X = hexToBitArray("0x0000000000000000");
    const Y = hexToBitArray("0xFFFFFFFFFFFFFFFF");
    const expected = "0000000000000000";
    const _res = await circuit.compute({ x: X, y: Y }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 32);

    assert.equal(result, expected, "parse incorrect");
  });

  it("bmul64 multiplies large number", async () => {
    const X = hexToBitArray("0x1111111111111111");
    const Y = hexToBitArray("0x1111111111111111");
    const expected = "101010101010101";
    const _res = await circuit.compute({ x: X, y: Y }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 32);

    assert.equal(result, expected, "parse incorrect");
  });

  // it("bmul64 multiplies large number 2", async () => {
  //   const X = hexToBitArray("0x1111222211118888");
  //   const Y = hexToBitArray("0x1111222211118888");
  //   const expected = "101010140404040";
  //   const _res = await circuit.compute({ x: X, y: Y }, ["out"]);
  //   const result = bitArrayToHex(
  //     (_res.out as number[]).map((bit) => Number(bit))
  //   ).slice(0, 32);

  //   assert.equal(result, expected, "parse incorrect");
  // });
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
    // const _res = await circuit.compute({ h: X, rhs: Y }, ["out"]);
    // const result = bitArrayToHex(
    //   (_res.out as number[]).map((bit) => Number(bit))
    // ).slice(0, 32);
    // console.log("expect: ", EXPECT, "\nresult: ", result);
    // assert.equal(result, EXPECT);
  });
});
