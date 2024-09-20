import { WitnessTester } from "circomkit";
import { bitArrayToHex, circomkit, hexToBitArray } from ".";
import { assert } from "chai";

describe("reverse_byte_array", () => {
  let circuit: WitnessTester<["in"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`reverse_bytes`, {
      file: "aes-gcm/helper_functions",
      template: "ReverseByteArray128",
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


describe("IncrementWord", () => {
  let circuit: WitnessTester<["in"], ["out"]>;
  it("should increment the word input", async () => {
      circuit = await circomkit.WitnessTester(`IncrementByte`, {
          file: "aes-gcm/utils",
          template: "IncrementWord",
      });
      await circuit.expectPass(
          {
              in: [0x00, 0x00, 0x00, 0x00],
          },
          {
              out: [0x00, 0x00, 0x00, 0x01],
          }
      );

  });
  it("should increment the word input on overflow", async () => {
      circuit = await circomkit.WitnessTester(`IncrementWord`, {
          file: "aes-gcm/utils",
          template: "IncrementWord",
      });
      await circuit.expectPass(
          {
              in: [0x00, 0x00, 0x00, 0xFF],
          },
          {
              out: [0x00, 0x00, 0x01, 0x00],
          }
      );
  });
  it("should increment the word input on overflow", async () => {
      circuit = await circomkit.WitnessTester(`IncrementWord`, {
          file: "aes-gcm/utils",
          template: "IncrementWord",
      });
      await circuit.expectPass(
          {
              in: [0xFF, 0xFF, 0xFF, 0xFF],
          },
          {
              out: [0x00, 0x00, 0x00, 0x00],
          }
      );
  });
});

describe("IncrementByte", () => {
  let circuit: WitnessTester<["in"], ["out"]>;
  it("should increment the byte input", async () => {
      circuit = await circomkit.WitnessTester(`IncrementByte`, {
          file: "aes-gcm/utils",
          template: "IncrementByte",
      });
      await circuit.expectPass(
          {
              in: 0x00,
          },
          {
              out: 0x01,
          }
      );
  });

  it("should increment the byte input on overflow", async () => {
      circuit = await circomkit.WitnessTester(`IncrementByte`, {
          file: "aes-gcm/utils",
          template: "IncrementByte",
      });
      await circuit.expectPass(
          {
              in: 0xFF,
          },
          {
              out: 0x00,
          }
      );
  });
});

describe("ParseBytesBE", () => {
  let circuit: WitnessTester<["in"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`ParseBEBytes64`, {
      file: "aes-gcm/helper_functions",
      template: "ParseBEBytes64",
    });
  });

  it("Should parse bytes in BE order", async () => {
    const X = hexToBitArray("0x0000000000000001");
    const expected = 1;
    const _result = await circuit.compute({ in: X }, ["out"]);
    const result = _result.out as number;

    assert.equal(result, expected, "parse incorrect");
  });
});


describe("ParseBytesLE", () => {
  let circuit: WitnessTester<["in"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`ParseLEBytes64`, {
      file: "aes-gcm/helper_functions",
      template: "ParseLEBytes64",
    });
  });

  it("Should parse bytes in LE order", async () => {
    const X = hexToBitArray("0x0100000000000000");
    const expected = 1;
    const _result = await circuit.compute({ in: X }, ["out"]);
    const result = _result.out as number;

    assert.equal(result, expected, "parse incorrect");
  });
});