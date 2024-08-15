import { WitnessTester } from "circomkit";
import { circomkit } from "../common";

// Polyval polynomial: x^128 + x^127 + x^126 + x^121 + 1
// "POLYVAL takes the least significant to most significant bits of the first byte to be the coefficients of x^0 to x^7"
const POLYVAL_H: number[] = byteStringToBitArray('00000000000000000000000000000000') // TODO Figure out the correct representation of that above polynomial to use here

const POLYVAL_T: number[][] = [
  byteStringToBitArray('0000000000000000'),
  byteStringToBitArray('0000000000000000')
] // TODO figure out what to use here

describe("polyval", () => {
  let circuit: WitnessTester<["in"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`polyval`, {
      file: "aes-gcm/polyval",
      template: "POLYVAL",
      params: [128],
    });
    console.log("#constraints:", await circuit.getConstraintCount());
  });

  it("should have correct number of constraints", async () => {
    await circuit.expectConstraintCount(74754, true);
  });
  
  // NOTE Test vectors are from https://datatracker.ietf.org/doc/html/rfc8452#appendix-A
  it("passes basic test vector", async () => {
    const input = byteStringToBitArray('01000000000000000000000000000000')
    const expected_output = byteStringToBitArray('02000000000000000000000000000000')

    await circuit.expectPass(
      // TODO Write this as a dictionary instead of an array
      { in: [input, POLYVAL_H, POLYVAL_T] },
      { out: expected_output }
    )
  });

  it("passes general test vector", async () => {
    const input = byteStringToBitArray('9c98c04df9387ded828175a92ba652d8')
    const expected_output = byteStringToBitArray('3931819bf271fada0503eb52574ca5f2')

    await circuit.expectPass(
      { in: [input, POLYVAL_H, POLYVAL_T] },
      { out: expected_output }
    )
  });
});

// Convert the byte string to an array of bits
function byteStringToBitArray(s: string): number[] {
  return s
  .split('')
  // Byte string to bit string
  .flatMap(byte => {
    return parseInt(byte, 16)
    .toString(2)
    .padStart(4, '0')
    .split('')
  })
  .map(x => parseInt(x))
}