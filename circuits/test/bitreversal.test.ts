import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { circomkit } from "./common";

describe("bitreversal", () => {
  let circuit: WitnessTester<["in"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`bitreversal`, {
      file: "aes-gcm/helper_functions",
      template: "ReverseBitsArray",
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