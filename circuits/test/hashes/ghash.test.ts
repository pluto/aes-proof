import { WitnessTester } from "circomkit";
import { bitArrayToHex, circomkit, hexToBitArray } from "../common";
import { assert } from "chai";

const H = "25629347589242761d31f826ba4b757b";
const X1 = "4f4f95668c83dfb6401762bb2d01a262";
const X2 = "d1a24ddd2721d006bbe45f20d3c9f362";

describe("ghash", () => {
  let circuit: WitnessTester<["in"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`ghash`, {
      file: "aes-gcm/hashes",
      template: "GHASH",
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
      (_res.out as (number | bigint)[]).map((bit) => Number(bit))
    );
    // console.log("expect: ", expect, "\nresult: ", result);
    assert.equal(expect, result);
  });
});
