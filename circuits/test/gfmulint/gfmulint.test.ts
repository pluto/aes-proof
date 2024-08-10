import { WitnessTester } from "circomkit";
import { circomkit } from "../common";
import { assert } from "chai";

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

  it("should output correct gfmul", async() => {
    // Find an example input without hash

    // need [2][64] field element long list for a,b
    // these will be multiplied, modulo something

    // input nums
    //
    // a = 1024
    // b = 2048
    // a*b = 2,097,152

    const a = 1;
    const b = 1;
    const zero = 0;
    const expected = a*b;

    // little endian pad a, b, zero
    const zero_bits = pad_to_64_bits(zero);
    const a_bits = pad_to_64_bits(a);
    const b_bits = pad_to_64_bits(b);
    
    let input = {a: [zero_bits, a_bits], b: [zero_bits, b_bits]};
    let wit = await circuit.calculateWitness(input);

    // circuit.expectPass(input, {res: })
    // let res = await circuit.expectConstraintPass(wit);

    let _res = await circuit.compute(input, ["res"])
    let result = parse_res(_res.res as number[][]);
    assert.equal(result, expected);
    console.log(`${a} x ${b} = ${result}`);
  });
});

function pad_to_64_bits(value: number): number[] {
  return value.toString(2).padStart(64, '0').split('').map(bit => parseInt(bit, 10));
}

// write a helper function to parse res
function parse_res(res: number[][]): number {
  let first_64: number[] = res[0];
  let last_64: number[] = res[1];
  let all_bits: number[] = first_64.concat(last_64);
  return parseInt(all_bits.join(''), 2);
}