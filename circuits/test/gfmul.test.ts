import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { padArrayTo64Bits, bitArrayToHex, circomkit, hexToBitArray, numberTo16Hex, numberToBitArray } from "./common";

const ZERO = hexToBitArray("0x000000000000000");
const ONE = hexToBitArray("0x0000000000000001");
const MAX = hexToBitArray("0xFFFFFFFFFFFFFFFF");

describe("BMUL64", () => {
  let circuit: WitnessTester<["x", "y"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`BMUL64`, {
      file: "aes-gcm/gfmul",
      template: "BMUL64",
    });
  });

  it("bmul64 multiplies 1", async () => {
    const expected = "0000000000000001";
    const _res = await circuit.compute({ x: ONE, y: ONE }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 32);

    assert.equal(result, expected, "parse incorrect");
  });

  it("bmul64 multiplies 0", async () => {
    const expected = "0000000000000000";
    const _res = await circuit.compute({ x: ZERO, y: MAX }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 32);

    assert.equal(result, expected, "parse incorrect");
  });

  it("bmul64 multiplies large number", async () => {
    const X = hexToBitArray("0x1111111111111111");
    const Y = hexToBitArray("0x1111111111111111");
    const expected = "0101010101010101";
    const _res = await circuit.compute({ x: X, y: Y }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 32);

    assert.equal(result, expected, "parse incorrect");
  });

  it("bmul64 multiplies large number 2", async () => {
    const X = hexToBitArray("0x1111222211118888");
    const Y = hexToBitArray("0x1111222211118888");
    const expected = "0101010140404040";
    const _res = await circuit.compute({ x: X, y: Y }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 32);

    assert.equal(result, expected, "parse incorrect");
  });

  it("bmul64 multiplies large number 3", async () => {
    const X = hexToBitArray("0xCFAF222D1A198287");
    const Y = hexToBitArray("0xFBFF2C2218118182");
    const expected = "40468c9202c4418e";
    const _res = await circuit.compute({ x: X, y: Y }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 32);

    assert.equal(result, expected, "parse incorrect");
  });
});

describe("GF_MUL", () => {
  let circuit: WitnessTester<["a", "b"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`MUL64`, {
      file: "aes-gcm/gfmul",
      template: "MUL",
    });
  });

  it("GF_MUL 0", async () => {
    const expected = "0000000000000000";
    const _res = await circuit.compute({ a: [MAX, MAX], b: [ZERO, ZERO] }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 64);

    assert.deepEqual(result, expected, "parse incorrect");
  });

  it("GF_MUL 1", async () => {
    const expected = "0000000000000001";

    const _res = await circuit.compute({ a: [ZERO, ONE], b: [ZERO, ONE] }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 64);

    assert.equal(result, expected, "parse incorrect");
  });

  it("GF_MUL 2", async () => {
    const expected = "C323456789ABCDEF0000000000000001";
    const _res = await circuit.compute({ a: [ZERO, ONE], b: [ONE, ZERO] }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 64);

    assert.equal(result, expected, "parse incorrect");
  });

  it("GF_MUL 3", async () => {
    const A = hexToBitArray("0x00000000000000F1");
    const B = hexToBitArray("0x000000000000BB00");
    const expected = "006F2B000000000000000000";

    const _res = await circuit.compute({ a: [ZERO, A], b: [ZERO, B] }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 64);

    assert.equal(result, expected, "parse incorrect");
  });

  it("GF_MUL 4", async () => {
    const A = hexToBitArray("0x00000000000000F1");
    const B = hexToBitArray("0x000000000000BB00");
    const expected = "006F2B000000000000000000";

    const _res = await circuit.compute({ a: [ZERO, A], b: [B, ZERO] }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 64);

    assert.equal(result, expected, "parse incorrect");
  });

  it("GF_MUL 5", async () => {
    const expected = "55555555555555557A01555555555555";

    const _res = await circuit.compute({ a: [MAX, MAX], b: [MAX, MAX] }, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[]).map((bit) => Number(bit))
    ).slice(0, 64);

    assert.equal(result, expected, "parse incorrect");
  });
});
