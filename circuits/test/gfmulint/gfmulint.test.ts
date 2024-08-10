import { WitnessTester } from "circomkit";
import { circomkit } from "../common";

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

    var a = 1;
    var b = 2;
    var zero = 0;

    const zero_bits = zero.toString(2).padStart(64, '0').split('').map(bit => parseInt(bit, 10));
    const a_bits = a.toString(2).padStart(64, '0').split('').map(bit => parseInt(bit, 10));
    const b_bits = b.toString(2).padStart(64, '0').split('').map(bit => parseInt(bit, 10));
    
    let input = {a: [zero_bits, a_bits], b: [zero_bits, b_bits]};
    let wit = await circuit.calculateWitness(input);

    // circuit.expectPass(input, {res: })
    // let res = await circuit.expectConstraintPass(wit);

    let res = await circuit.compute(input, ["res"])
    let first_64: number[] = (res.res as number[][])[0];
    let last_64: number[] = (res.res as number[][])[1]
    let all_bits: number[] = first_64.concat(last_64);
    console.log("output:", parseInt(all_bits.join(''), 2));
  });
});