import { WitnessTester } from "circomkit";
import { circomkit } from "../common";

describe("ghash", () => {
  let circuit: WitnessTester<["in"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`ghash`, {
      file: "aes-gcm/hashes",
      template: "GHASH",
      params: [128],
    });
    // console.log("#constraints:", await circuit.getConstraintCount());
  });

  it("test ghash", async () => {
  //   let bits = hexToBitArray("01000000000000000000000000000000");
  //   for (let i = 0; i < mulXTestVectors.length; i++) {
  //     const expect = mulXTestVectors[i];
  //     const _res = await circuit.compute({ in: bits }, ["out"]);
  //     const result = bitArrayToHex(
  //       (_res.out as (number | bigint)[]).map((bit) => Number(bit))
  //     );
  //     // console.log("expect: ", expect, "\nresult: ", result);
  //     assert.equal(expect, result);
  //     bits = hexToBitArray(result);
  //   }
  });
});
