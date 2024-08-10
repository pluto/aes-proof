import { WitnessTester } from "circomkit";
import { circomkit } from "../common";
import { assert } from "chai";
import { parse } from "path";

// input and output type of GFMULInt
type Arr128 = number[][];

describe("gfmulint", () => {
  let circuit: WitnessTester<["a", "b"], ["res"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester("gfmulint", {
      file: "aes/gfmul_int",
      template: "GFMULInt",
    });
    console.log("#constraints:", await circuit.getConstraintCount());
  });

  it("should have correct number of constraints", async () => {
    await circuit.expectConstraintCount(74626, true);
  });

  // TODO(TK 2024-08-10):
  it("should output correct gfmul", async () => {
    const a = 1;
    const b = 1;
    const expected = a * b;
    const input = { a: pad_num_to_arr128(a), b: pad_num_to_arr128(b) };

    let _res = await circuit.compute(input, ["res"]);
    let result = parse_arr128_to_number(_res.res as Arr128);
    console.log(`${a} x ${b} = ${result}`);
    assert.equal(result, expected);
  });
});

// parse `value` to two 64-bit little-endian arrays
function pad_num_to_arr128(value: number): Arr128 {
  let tmp = value
    .toString(2)
    .padStart(128, "0")
    .split("")
    .map((bit) => parseInt(bit, 10));
  return [tmp.slice(0, 64), tmp.slice(64, 128)];
}

function parse_arr128_to_number(res: Arr128): number {
  let first_64: number[] = res[0];
  let last_64: number[] = res[1];
  let all_bits: number[] = first_64.concat(last_64);
  return parseInt(all_bits.join(""), 2);
}
