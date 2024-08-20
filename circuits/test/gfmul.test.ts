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