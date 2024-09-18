import { WitnessTester } from "circomkit";
import { bitArrayToHex, circomkit, hexToBitArray } from "../common";
import { assert } from "chai";

// https://datatracker.ietf.org/doc/html/rfc8452#appendix-A
const H = hexToBitArray("25629347589242761d31f826ba4b757b");
const X1 = "4f4f95668c83dfb6401762bb2d01a262";
const X2 = "d1a24ddd2721d006bbe45f20d3c9f362";
const M = hexToBitArray(X1.concat(X2));
const EXPECT = hexToBitArray("bd9b3997046731fb96251b91f9c99d7a");

describe("GHASH_HASH", () => {
  let circuit: WitnessTester<["HashKey", "msg"], ["tag"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`ghash`, {
      file: "aes-gcm/ghash",
      template: "GHASH",
      params: [2],
    });
    // console.log("#constraints:", await circuit.getConstraintCount());
  });

  it("test ghash", async () => {
    const input = { HashKey: H, msg: M };
    console.log("input message length: ", input.msg.length);
    console.log("input hash key length: ", input.HashKey.length);
    console.log("input message: ", EXPECT);
    const _res = await circuit.expectPass(input, { tag: EXPECT });
  });
});

describe("TranslateHashkey", () => {
  let circuit: WitnessTester<["inp"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`ghash`, {
      file: "aes-gcm/ghash",
      template: "TranslateHashkey",
    });
    // console.log("#constraints:", await circuit.getConstraintCount());
  });

  // initial hashkey: [37, 98, 147, 71, 88, 146, 66, 118, 29, 49, 248, 38, 186, 75, 117, 123]
  //25629347589242761D31F826BA4B757B
  // reversed hashkey: [123, 117, 75, 186, 38, 248, 49, 29, 118, 66, 146, 88, 71, 147, 98, 37]
  //7B754BBA26F8311D7642925847936225
  // post-mul_x hashkey: [246, 234, 150, 116, 77, 240, 99, 58, 236, 132, 36, 177, 142, 38, 197, 74]
  //F6EA96744DF0633AEC8424B18E26C54A
  it("test TranslateHashkey", async () => {
    const inp = hexToBitArray("25629347589242761d31f826ba4b757b");
    const out = hexToBitArray("F6EA96744DF0633AEC8424B18E26C54A");
    const _res = await circuit.expectPass({ inp: inp }, { out });
  });
});



