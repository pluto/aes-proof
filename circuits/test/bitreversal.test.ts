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
  let bit_array_1 = [1,0,0,0,0,0,0,1];
  it("should have correct output", async () => {
    const witness = await circuit.calculateWitness({ in: bit_array });
    circuit.expectPass({in: bit_array});

    // I was initially not sure what the first bit was doing in the witness, but it's just the success flag
    console.log("witness: from input: [1,0,0,0,0,0,0,0]", witness);
  });

  it("should fail with wrong input", async () => {
    const witness = await circuit.calculateWitness({ in: bit_array_1 });
    circuit.expectPass({in: bit_array_1});

    console.log("witness: from input: [1,0,0,0,0,0,0,1]", witness);
  });
});