import { WitnessTester } from "circomkit";
import { bitArrayToHex, circomkit, hexToBitArray } from "../common";

// https://datatracker.ietf.org/doc/html/rfc8452#appendix-A


const H = [
  [0x25, 0x62, 0x93, 0x47],
  [0x58, 0x92, 0x42, 0x76],
  [0x1d, 0x31, 0xf8, 0x26],
  [0xba, 0x4b, 0x75, 0x7b]
];

const hash_key = [
  [0xaa, 0xe0, 0x69, 0x92],
  [0xac, 0xbf, 0x52, 0xa3],
  [0xe8, 0xf4, 0xa9, 0x6e],
  [0xc9, 0x30, 0x0b, 0xd7]
];
const cipher_text = [
  [0x98, 0xe7, 0x24, 0x7c],
  [0x07, 0xf0, 0xfe, 0x41],
  [0x1c, 0x26, 0x7e, 0x43],
  [0x84, 0xb0, 0xf6, 0x00]
];

const tag = hexToBitArray("2ff58d80033927ab8ef4d4587514f0fb");

describe("ghash", () => {
  let circuit: WitnessTester<["HashKey", "msg"], ["tag"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`ghash`, {
      file: "aes-gcm/ghash",
      template: "GHASH",
      params: [1],
    });
    // console.log("#constraints:", await circuit.getConstraintCount());
  });

  it("test ghash", async () => {
    const input = { HashKey: hash_key, msg: cipher_text };
    console.log("input message length: ", input.msg.length);
    console.log("input hash key length: ", input.HashKey.length);
    console.log("input message: ", tag);
    const _res = await circuit.expectPass(input, { tag: tag });
  });
});