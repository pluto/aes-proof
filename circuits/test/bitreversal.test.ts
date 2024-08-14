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
  let expected_output = [0,0,0,0,0,0,0,1];
  it("should have correct output", async () => {
    const witness = await circuit.expectPass({ in: bit_array}, { out: expected_output });
    circuit.expectPass({in: bit_array});

    // I was initially not sure what the first bit was doing in the witness, but it's just the success flag
    console.log("witness: from input: [1,0,0,0,0,0,0,0]", witness);
  });

});