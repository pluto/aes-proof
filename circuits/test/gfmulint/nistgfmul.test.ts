import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { circomkit, hexToBitArray, hexByteToBigInt } from "../common";


describe("nist", () => {
  let circuit: WitnessTester<["X", "Y"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester("nistgfmul", {
      file: "aes-gcm/nistgmul",
      template: "NistGMulBit",
    });
    console.log("#constraints:", await circuit.getConstraintCount());
  });

  it("Should Compute NistGMulBit Correctly", async () => {
    let X = hexToBitArray("0xaae06992acbf52a3e8f4a96ec9300bd7");   // little endian hex vectors
    let Y = hexToBitArray("0x98e7247c07f0fe411c267e4384b0f600");
  

    const expected = hexToBitArray("0x2ff58d80033927ab8ef4d4587514f0fb");
    const _res = await circuit.compute({ X, Y }, ["out"]);
    assert.deepEqual(_res.out, expected);
  });
});

describe("ToBits", () => {
    let circuit: WitnessTester<["in"], ["out"]>;
  
    before(async () => {
      circuit = await circomkit.WitnessTester("bytesToBits", {
        file: "aes-gcm/nistgmul",
        template: "BytesToBits",
        params: [1]
      });
      console.log("#constraints:", await circuit.getConstraintCount());
    });

    it("Should Compute bytesToBits Correctly", async () => {
        let input = 0x01;
        const expected = hexToBitArray("0x01");
        console.log("expected", expected);
        const _res = await circuit.expectPass({ in: input }, { out: expected });
    });
    it("Should Compute bytesToBits Correctly", async () => {
        let input = 0xFF;
        const expected = hexToBitArray("0xFF");
        console.log("expected", expected);
        const _res = await circuit.expectPass({ in: input }, { out: expected });
    });
});
describe("ToBits", () => {
    let circuit: WitnessTester<["in"], ["out"]>;
  
    before(async () => {
      circuit = await circomkit.WitnessTester("bytesToBits", {
        file: "aes-gcm/nistgmul",
        template: "BytesToBits",
        params: [2]
      });
      console.log("#constraints:", await circuit.getConstraintCount());
    });

    it("Should Compute bytesToBits Correctly", async () => {
        let input = [0x01, 0x00];
        const expected = hexToBitArray("0x0100");
        console.log("expected", expected);
        const _res = await circuit.expectPass({ in: input }, { out: expected });
    });
    it("Should Compute bytesToBits Correctly", async () => {
        let input = [0xFF, 0x00];
        const expected = hexToBitArray("0xFF00");
        console.log("expected", expected);
        const _res = await circuit.expectPass({ in: input }, { out: expected });
    });
});

describe("ToBytes", () => {
    let circuit: WitnessTester<["in"], ["out"]>;
  
    before(async () => {
      circuit = await circomkit.WitnessTester("bytesToBits", {
        file: "aes-gcm/nistgmul",
        template: "BitsToBytes",
        params: [1]
      });
      console.log("#constraints:", await circuit.getConstraintCount());
    });

    it("Should Compute bytesToBits Correctly", async () => {
        let input = hexToBitArray("0x01");
        const expected = hexByteToBigInt("0x01");
        console.log("expected", expected);
        const _res = await circuit.compute({ in: input }, ["out"]);
        console.log("res:", _res.out);
        assert.deepEqual(_res.out, expected);
    });
    it("Should Compute bytesToBits Correctly", async () => {
        let input = hexToBitArray("0xFF");
        const expected = hexByteToBigInt("0xFF");
        console.log("expected", expected);
        const _res = await circuit.compute({ in: input }, ["out"]);
        console.log("res:", _res.out);
        assert.deepEqual(_res.out, expected);
    });
});


describe("intrightshift", () => {
    let circuit: WitnessTester<["in"], ["out"]>;
  
    before(async () => {
      circuit = await circomkit.WitnessTester("intrightshift", {
        file: "aes-gcm/helper_functions",
        template: "IntRightShift",
        params: [8, 1]
      });
      console.log("#constraints:", await circuit.getConstraintCount());
    });
  
    it("Should Compute IntRightShift Correctly", async () => {
      let input = 0x02;   // little endian hex vectors
      const expected = hexByteToBigInt("0x01");
      const _res = await circuit.compute({ in: input }, ["out"]);
      console.log("res:", _res.out);
      assert.deepEqual(_res.out, expected);
    });

    it("Should Compute IntRightShift Correctly", async () => {
        let input = 0x04;   // little endian hex vectors
        const expected = hexByteToBigInt("0x02");
        const _res = await circuit.compute({ in: input }, ["out"]);
        console.log("res:", _res.out);
        assert.deepEqual(_res.out, expected);
      });
  });


  describe("BlockRightShift", () => {
    let circuit: WitnessTester<["in"], ["out", "msb"]>;
  
    before(async () => {
      circuit = await circomkit.WitnessTester("BlockRightShift", {
        file: "aes-gcm/nistgmul",
        template: "BlockRightShift",
      });
      console.log("#constraints:", await circuit.getConstraintCount());
    });

    it("Should Compute BlockRightShift Correctly", async () => {
        let input = [0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        const expected = [0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        const _res = await circuit.expectPass({ in: input }, { out: expected, msb: 0 });
    });
    it("Should Compute BlockRightShift Correctly", async () => {
        let input = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01];
        const expected = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        const _res = await circuit.expectPass({ in: input }, { out: expected, msb: 1 });
        // console.log("res:", _res.out);
        // assert.deepEqual(_res.out, expected);
        // console.log("msb:", _res.msb);
        // assert.deepEqual(_res.msb, 0x01);
    });
});