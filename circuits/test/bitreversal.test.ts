import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { bitArrayToHex, circomkit, hexToBitArray } from "./common";

describe("bitreversal", () => {
  let circuit: WitnessTester<["in"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`bitreversal`, {
      file: "aes-gcm/helper_functions",
      template: "ReverseArray",
      params: [8],
    });
  });

  let bit_array = [1,0,0,0,0,0,0,0];
  let expected_output = [0,0,0,0,0,0,0,1].map((x) => BigInt(x));
  it("should have correct output", async () => {
    const witness = await circuit.compute({ in: bit_array }, ["out"])

    assert.deepEqual(witness.out, expected_output)
  });

});
describe("reverse_byte_array", () => {
  let circuit: WitnessTester<["in"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`ghash`, {
      file: "aes-gcm/helper_functions",
      template: "ReverseByteArray",
    });
  });

  it("test reverse_byte_array", async () => {
    let bits = hexToBitArray("0102030405060708091011121314151f");
    let expect = "1f151413121110090807060504030201";
    const _res = await circuit.compute({ in: bits }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    );
    // console.log("expect: ", expect, "\nresult: ", result);
    assert.equal(expect, result);
  });
});