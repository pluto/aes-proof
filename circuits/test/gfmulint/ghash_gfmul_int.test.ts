import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { circomkit } from "../common";

// input and output type of GFMULInt
type Arr128 = number[][];
type _Arr128 = number[];

describe("mulX_polyval", () => {
  let circuit: WitnessTester<["in"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester("mulX_polyval", {
      file: "aes-gcm/helper_functions",
      template: "mulX_polyval",
    });
  });

  it("it should compute leftshift of one", async () => {
    let _res = await circuit.compute({ in: _pad_num_to_arr128(1) }, ["out"]);
    // console.log(`${_res.out}`);
    let res = _parse_arr128_to_number(_res.out as _Arr128);
    assert.equal(res, 2);
  });

  it("it should compute leftshift of two", async () => {
    let _res = await circuit.compute({ in: _pad_num_to_arr128(2) }, ["out"]);
    // console.log(`${_res.out}`);
    let res = _parse_arr128_to_number(_res.out as _Arr128);
    assert.equal(res, 4);
  });

  it("it should compute leftshift of 127", async () => {
    let input = [1, ...Array(127).fill(0)];
    let _res = await circuit.compute({ in: input }, ["out"]);
    console.log(`${_res.out}`);

    // recall
    // x^127 + x^126 + x^121 + 1
    let expected = [1, 1, 0, 0, 0, 0, 0, 1, ...Array(119).fill(0), 1];
    assert.equal(_res.out, expected);
  });
});

function _pad_num_to_arr128(value: number): _Arr128 {
  return value
    .toString(2)
    .padStart(128, "0")
    .split("")
    .map((bit) => parseInt(bit, 10));
}

function _parse_arr128_to_number(res: _Arr128): number {
  return parseInt(res.join(""), 2);
}
