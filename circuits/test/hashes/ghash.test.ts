import { WitnessTester } from "circomkit";
import { bitArrayToHex, circomkit, hexToBitArray } from "../common";
import { assert } from "chai";

const H = hexToBitArray("25629347589242761d31f826ba4b757b");
const X1 = "4f4f95668c83dfb6401762bb2d01a262";
const X2 = "d1a24ddd2721d006bbe45f20d3c9f362";
const M = hexToBitArray(X1.concat(X2));

describe("ghash-hash", () => {
  let circuit: WitnessTester<["in"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`ghash`, {
      file: "aes-gcm/hashes",
      template: "GHASH",
      params: [128 * 2],
    });
    // console.log("#constraints:", await circuit.getConstraintCount());
  });

  // https://datatracker.ietf.org/doc/html/rfc8452#appendix-A
  it("test ghash", async () => {
    const expect = "bd9b3997046731fb96251b91f9c99d7a";
    // console.log("input: ", input.length);

    const input = { msg: M, H: H };
    // const inp = { in: input, H: H };
    // const inp =  { msg: input, H: H }; // todo: circomkit forcing me to call msg ->"in"
    const _res = await circuit.compute(input, ["out"]);
    const result = bitArrayToHex(
      (_res.out as (number | bigint)[]).map((bit) => Number(bit))
    );
    console.log("expect: ", expect, "\nresult: ", result);
    assert.equal(expect, result);
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
