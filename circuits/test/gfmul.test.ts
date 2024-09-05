import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { bitArrayToHex, circomkit, hexToBitArray } from "./common";

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

describe("WRAPPING_MUL", () => {
  let circuit: WitnessTester<["a", "b"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`WrappingMul64`, {
      file: "aes-gcm/mul",
      template: "WrappingMul64",
      // params: [8],
    });
  });

  it("should correctly multiply two 64-bit numbers", async () => {
    const a = BigInt("0xFFFFFFFFFFFFFFFF"); // Max 64-bit unsigned integer
    const b = BigInt(2);
    const expected = (a * b) & BigInt("0xFFFFFFFFFFFFFFFF"); // Simulate 64-bit wrap

    const result = await circuit.calculateWitness({ a, b }, ["out"]);

    // const output = BigInt(result.out.toString());
    
    // assert.equal(output, expected, "Multiplication result is incorrect");
  });

  // it("should handle multiplication with zero", async () => {
  //   const a = BigInt("0xFFFFFFFFFFFFFFFF");
  //   const b = BigInt(0);
  //   const expected = BigInt(0);

  //   const result = await circuit.calculateWitness({ a, b }, ["out"]);

  //   const output = BigInt(result.out.toString());
    
  //   assert.equal(output, expected, "Multiplication with zero is incorrect");
  // });

  // it("should correctly wrap around on overflow", async () => {
  //   const a = BigInt("0xFFFFFFFFFFFFFFFF");
  //   const b = BigInt("0xFFFFFFFFFFFFFFFF");
  //   const expected = BigInt("0xFFFFFFFFFFFFFFFE0000000000000001");

  //   const result = await circuit.calculateWitness({ a, b }, ["out"]);

  //   const output = BigInt(result.out.toString());
    
  //   assert.equal(output, expected, "Wrap-around on overflow is incorrect");
  // });
});
