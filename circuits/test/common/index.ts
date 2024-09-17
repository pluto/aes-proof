import { assert } from "chai";
import { Circomkit, WitnessTester } from "circomkit";
import "mocha";

export const circomkit = new Circomkit({
  verbose: false,
});

export { WitnessTester };

export function hexBytesToBigInt(hexBytes: number[]): any[] {
  return hexBytes.map(byte => {
      let n = BigInt(byte);
      return n;
  });
}

export function hexToBitArray(hex: string): number[] {
  // Remove '0x' prefix if present and ensure lowercase
  hex = hex.replace(/^0x/i, "").toLowerCase();

  // Ensure even number of characters
  if (hex.length % 2 !== 0) {
    hex = "0" + hex;
  }

  return (
    hex
      // Split into pairs of characters
      .match(/.{2}/g)!
      .flatMap((pair) => {
        const byte = parseInt(pair, 16);
        // map byte to 8-bits. Apologies for the obtuse mapping;
        // which cycles through the bits in byte and extracts them one by one.
        return Array.from({ length: 8 }, (_, i) => (byte >> (7 - i)) & 1);
      })
  );
}

export function bitArrayToHex(bits: number[]): string {
  // console.log(bits);
  if (bits.length % 8 !== 0) {
    throw new Error("Input length must be a multiple of 8 bits");
  }

  return bits
    .reduce((acc, bit, index) => {
      const byteIndex = Math.floor(index / 8);
      const bitPosition = 7 - (index % 8);
      acc[byteIndex] = (acc[byteIndex] || 0) | (bit << bitPosition);
      return acc;
    }, new Array(bits.length / 8).fill(0))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

export function numberToBitArray(num: number): number[] {
  if (!Number.isInteger(num) || num < 0) {
    throw new Error('Input must be a non-negative integer');
  }

  if (num === 0) {
    return [0];
  }

  const bitArray: number[] = [];

  while (num > 0) {
    bitArray.unshift(num & 1);
    num = num >>> 1;  // Zero-fill right shift
  }

  return bitArray;
}

export function padArrayTo64Bits(array: number[]): number[] {
  if (array.length > 64) {
    throw new Error('Input array must have at most 64 elements');
  }
  return new Array(64 - array.length).fill(0).concat(array);
}

export function numberTo16Hex(num: number): string {
  // Convert the number to a hexadecimal string
  let hexString = num.toString(16);

  // Ensure the string is uppercase
  hexString = hexString.toLowerCase();

  // Pad with leading zeros if necessary
  hexString = hexString.padStart(16, '0');

  // If the number is too large and results in a string longer than 16 characters,
  // we'll take the last 16 characters to maintain the fixed length
  if (hexString.length > 16) {
    hexString = hexString.slice(-16);
  }

  return hexString;
}

it("tests hexToBitArray", async () => {
  let hex = "0F";
  let expectedBits = [0, 0, 0, 0, 1, 1, 1, 1];
  let result = hexToBitArray(hex);
  assert.deepEqual(result, expectedBits);

  hex = "1248";
  expectedBits = [0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0];
  result = hexToBitArray(hex);
  assert.deepEqual(result, expectedBits);
});

it("tests bitArrayToHexString", async () => {
  let bits = [0, 0, 0, 0, 1, 1, 1, 1];
  let expectedHex = "0f";
  let result = bitArrayToHex(bits);
  assert.equal(result, expectedHex);

  bits = [1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1];
  expectedHex = "8b09";
  result = bitArrayToHex(bits);
  assert.equal(result, expectedHex);
});
