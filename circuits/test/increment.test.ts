import { WitnessTester } from "circomkit";
import { circomkit } from "./common";

describe("Increment", () => {
  let circuit: WitnessTester<["in"], ["out"]>;
  it("should increment the input", async () => {
    circuit = await circomkit.WitnessTester(`Increment`, {
      file: "aes-gcm/helper_functions",
      template: "Increment32",
    });
    let res = await circuit.expectPass(
      {
        in: Array(128).fill(0),
      },
      {
        out: [...Array(127).fill(0), 1],
      }
    );
  });
});