import { WitnessTester } from "circomkit";
import { bitArrayToHex, circomkit, hexToBitArray } from "../common";
import { assert } from "chai";



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
    // https://datatracker.ietf.org/doc/html/rfc8452#appendix-A
    const H = [0x25, 0x62, 0x93, 0x47, 0x58, 0x92, 0x42, 0x76, 0x1d, 0x31, 0xf8, 0x26, 0xba, 0x4b, 0x75, 0x7b];
    const X1 = [0x4f, 0x4f, 0x95, 0x66, 0x8c, 0x83, 0xdf, 0xb6, 0x40, 0x17, 0x62, 0xbb, 0x2d, 0x01, 0xa2, 0x62];
    const X2 = [0xd1, 0xa2, 0x4d, 0xdd, 0x27, 0x21, 0xd0, 0x06, 0xbb, 0xe4, 0x5f, 0x20, 0xd3, 0xc9, 0xf3, 0x62];
    const M = X1.concat(X2);
    const EXPECT = [0xbd, 0x9b, 0x39, 0x97, 0x04, 0x67, 0x31, 0xfb, 0x96, 0x25, 0x1b, 0x91, 0xf9, 0xc9, 0x9d, 0x7a];
    const _res = await circuit.expectPass({ HashKey: H, msg: M }, { tag: EXPECT });
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



