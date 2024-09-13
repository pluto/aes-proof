
import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { circomkit, hexToBitArray } from "./common";

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

