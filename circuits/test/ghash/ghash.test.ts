import { WitnessTester } from "circomkit";
import { circomkit } from "../common";

describe("ghash", () => {
  let circuit: WitnessTester<["in"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`ghash`, {
      file: "aes/polyval",
      template: "POLYVAL",
      params: [128],
    });
  });

  it("should have correct number of constraints", async () => {
    await circuit.expectConstraintCount(1000);
  });
});