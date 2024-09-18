import { WitnessTester } from "circomkit";
import { bitArrayToHex, circomkit, hexToBitArray } from "../common";
import { assert } from "chai";

// https://datatracker.ietf.org/doc/html/rfc8452#appendix-A
const H = hexToBitArray("25629347589242761d31f826ba4b757b");
const X1 = "4f4f95668c83dfb6401762bb2d01a262";
const X2 = "d1a24ddd2721d006bbe45f20d3c9f362";
const M = hexToBitArray(X1.concat(X2));
const EXPECT = hexToBitArray("bd9b3997046731fb96251b91f9c99d7a");

// Thor this is the test for GMUL you asked for <3
describe("gfmul", () => {
  let circuit: WitnessTester<["a", "b"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`gfmul`, {
      file: "aes-gcm/gfmul",
      template: "GMUL",
    });
  });

  // these test vectors are from rust-crypto
  // to reproduce run `cargo test ghash -- --nocapture`
  // let hash_key = [0xaa, 0xe0, 0x69, 0x92, 0xac, 0xbf, 0x52, 0xa3, 0xe8, 0xf4, 0xa9, 0x6e, 0xc9, 0x30, 0x0b, 0xd7];
  // let ct = [0x98, 0xe7, 0x24, 0x7c, 0x07, 0xf0, 0xfe, 0x41, 0x1c, 0x26, 0x7e, 0x43, 0x84, 0xb0, 0xf6, 0x00];
  // let expected = [0x2f, 0xf5, 0x8d, 0x80, 0x03, 0x39, 0x27, 0xab,0x8e, 0xf4, 0xd4, 0x58, 0x75, 0x14, 0xf0, 0xfb];

  // i don't know what api you were going to build so here they are broken into lower and upper 64 bit vectors
  let lower_h = hexToBitArray("0xaae06992acbf52a3");   // little endian hex vectors
  let upper_h = hexToBitArray("0xe8f4a96ec9300bd7");
    
  let lower_x = hexToBitArray("0x98e7247c07f0fe41");
  let upper_x = hexToBitArray("0x1c267e4384b0f600");


  it("test gmul", async () => {
    const input = { a: H, b: M };
    const _res = await circuit.expectPass(input, { out: EXPECT });
  });
});



describe("ghash-hash", () => {
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
      (_res.out as number[]).map((bit) => Number(bit))
    );
    // console.log("expect: ", expect, "\nresult: ", result);
    assert.equal(expect, result);
  });
});
