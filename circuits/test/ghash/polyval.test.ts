import { WitnessTester } from "circomkit";
import { circomkit } from "../common";

describe("polyval", () => {
  let circuit: WitnessTester<["in"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`polyval`, {
      file: "aes/polyval",
      template: "POLYVAL",
      params: [128],
    });
    console.log("#constraints:", await circuit.getConstraintCount());
  });

  it("should have correct number of constraints", async () => {
    await circuit.expectConstraintCount(74754, true);
  });
});