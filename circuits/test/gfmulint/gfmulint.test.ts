import { WitnessTester } from "circomkit";
import { circomkit } from "../common";


/// in ghash this polynomial is x^128 + x^7 + x^2 + x + 1
describe("gfmulint", () => {
  let circuit: WitnessTester<["a", "b"], ["res"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester("gfmulint", {
      file: "aes-gcm/gfmul_int",
      template: "GFMULInt",
    });
    console.log("#constraints:", await circuit.getConstraintCount());
  });

  it("should have correct number of constraints", async () => {
    await circuit.expectConstraintCount(74626, true);
  });

  it("should output correct gfmul", async () => {
    /// x^128 = x^7 + x^2 + x + 1 -> 10000111
    // Construct a 128-bit array with only the leftmost (most significant) bit set
    const a_bits = new Array(128).fill(0);
    a_bits[0] = 1;

    /// ( x^7 + x^2 + x + 1 ) * ( x^7 + x^2 + x + 1 ) = x^14 + x^4 + x^2 + 1 in this extension field
    /// You can verify this in wolfwram alpha over the real numbers and then taking the resulting coefficients mod 2
    /// x^14 + x^4 + x^2 + 1 -> 10001010000010 is the right most 15 bits of the expected result
    let expected_bit_array = [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0];

    await circuit.expectPass( { a: a_bits, b: a_bits }, { res: expected_bit_array });
  });
});