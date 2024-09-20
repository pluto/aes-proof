import { WitnessTester } from "circomkit";
import { bitArrayToHex, circomkit, hexToBitArray } from "./common";
import { assert } from "chai";

describe("reverse_byte_array", () => {
  let circuit: WitnessTester<["in"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`reverse_bytes`, {
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

