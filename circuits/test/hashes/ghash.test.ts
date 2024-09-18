import { WitnessTester } from "circomkit";
import { bitStringToHex, circomkit, hexToBitArray } from "../common";
import { assert } from "chai";

// https://datatracker.ietf.org/doc/html/rfc8452#appendix-A

// test vectors from this document: https://csrc.nist.rip/groups/ST/toolkit/BCM/documents/proposedmodes/gcm/gcm-spec.pdf 
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
  [0x84, 0xb0, 0xf6, 0x00],
];

const tag = hexToBitArray("90e87315fb7d4e1b4092ec0cbfda5d7d");

describe("ghash", () => {
  let circuit: WitnessTester<["HashKey", "ciphertext"], ["tag"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`ghash`, {
      file: "aes-gcm/ghash",
      template: "GHASH",
      params: [1],
    });
    // console.log("#constraints:", await circuit.getConstraintCount());
  });

  it("test ghash", async () => {
    const input = { HashKey: hash_key, ciphertext: cipher_text };
    console.log("input message length: ", input.ciphertext.length);
    console.log("input hash key length: ", input.HashKey.length);
    console.log("input message: ", tag);
    // const _res = await circuit.expectPass(input, { tag: tag });

    const witness = await circuit.compute({ HashKey: hash_key, ciphertext: cipher_text }, ["tag"])
    console.log("witness tag", bitStringToHex(witness.tag.toString()));
    assert.deepEqual(witness.tag, tag);

  });
});