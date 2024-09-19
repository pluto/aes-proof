import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { circomkit, hexToBitArray, hexByteToBigInt, hexStringToByteArray, byteArrayToHex } from "../common";


describe("NistGMulByte", () => {
  let circuit: WitnessTester<["X", "Y"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester("nistgfmul", {
      file: "aes-gcm/nistgmul",
      template: "NistGMulByte",
    });
    console.log("#constraints:", await circuit.getConstraintCount());
  });

  it("Should Compute NistGMulByte Correctly", async () => {

    let X  = [0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
    let Y = [0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
  
    const expected = [0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
    await circuit.expectPass({ X: X, Y: Y }, { out: expected });
  });

  it("Should Compute NistGMulByte of LSB=1 Correctly", async () => {

    let X  = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01];
    let Y = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01];
  
    const expected = [0xe6, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03];
    await circuit.expectPass({ X: X, Y: Y }, { out: expected });
  });
});

describe("debug1", () => {
    let circuit: WitnessTester<["X", "Y"], ["out"]>;
  
    before(async () => {
      circuit = await circomkit.WitnessTester("debug1", {
        file: "aes-gcm/nistgmul",
        template: "debug_1_byte",
      });
      console.log("#constraints:", await circuit.getConstraintCount());
    });

    it("Should Compute Correctly", async () => {
        let inputX = [0x80];
        let inputY = [0x80];
        const expected = [0x80];
        console.log("expected", expected);
        const _res = await circuit.expectPass({ X: inputX, Y: inputY }, { out: expected });
    });
    it("Should Compute Correctly", async () => {
        let inputX = [0x01];
        let inputY = [0x01];

        const expected = [0x5E];
        console.log("expected", expected);
        await circuit.expectPass({ X: inputX, Y: inputY }, { out: expected });
    });
});

describe("debug2", () => {
    let circuit: WitnessTester<["X", "Y"], ["out"]>;
  
    before(async () => {
      circuit = await circomkit.WitnessTester("debug1", {
        file: "aes-gcm/nistgmul",
        template: "debug_2_bytes",
      });
      console.log("#constraints:", await circuit.getConstraintCount());
    });

    it("Should Compute Correctly", async () => {
        let inputX = [0x80, 0x00];
        let inputY = [0x80, 0x00];
        const expected = [0x80, 0x00];
        console.log("expected", expected);
        const _res = await circuit.expectPass({ X: inputX, Y: inputY }, { out: expected });
    });
    it("Should Compute Correctly", async () => {
        let inputX = [0x00, 0x01];
        let inputY = [0x00, 0x01];

        const expected = [0xE6, 0x0B];
        console.log("expected", expected);
        await circuit.expectPass({ X: inputX, Y: inputY }, { out: expected });
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
        params: [16]
      });
      console.log("#constraints:", await circuit.getConstraintCount());
    });

    it("Should Compute BlockRightShift Correctly", async () => {
        let input = [0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        const expected = [0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        await circuit.expectPass({ in: input }, { out: expected, msb: 0 });
    });
    it("Should Compute BlockRightShift Correctly", async () => {
        let input = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01];
        const expected = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        await circuit.expectPass({ in: input }, { out: expected, msb: 1 });
    });
});

describe("Mulx", () => {
    let circuit: WitnessTester<["in"], ["out"]>;
  
    before(async () => {
      circuit = await circomkit.WitnessTester("Mulx", {
        file: "aes-gcm/nistgmul",
        template: "Mulx",
        params: [16]
      });
      console.log("#constraints:", await circuit.getConstraintCount());
    });
    // msb is 1 so we xor the first byte with 0xE1
    it("Should Compute Mulx Correctly", async () => {
        let input = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01];
        const expected = [0xE1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        await circuit.expectPass({ in: input }, { out: expected });
    });
});

describe("XORBLOCK", () => {
    let circuit: WitnessTester<["a", "b"], ["out"]>;
  
    before(async () => {
      circuit = await circomkit.WitnessTester("XORBLOCK", {
        file: "aes-gcm/nistgmul",
        template: "XORBLOCK",
        params: [16]
      });
      console.log("#constraints:", await circuit.getConstraintCount());
    });
    // msb is 1 so we xor the first byte with 0xE1
    it("Should Compute block XOR Correctly", async () => {
        let inputa = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        let inputb = [0xE1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01];
        const expected = [0xE1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01];
        await circuit.expectPass({ a: inputa, b: inputb }, { out: expected });
    });
});
describe("ArrayMux", () => {
    let circuit: WitnessTester<["a", "b", "sel"], ["out"]>;
  
    before(async () => {
      circuit = await circomkit.WitnessTester("XORBLOCK", {
        file: "aes-gcm/nistgmul",
        template: "ArrayMux",
        params: [16]
      });
      console.log("#constraints:", await circuit.getConstraintCount());
    });
    // msb is 1 so we xor the first byte with 0xE1
    it("Should Compute selector mux Correctly", async () => {
        let a= [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        let b = [0xE1, 0xE1, 0xE1, 0xE1, 0xE1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01];
        let sel = 0x00;
        let expected= [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        await circuit.expectPass({ a: a, b: b, sel: sel }, { out: expected });
    });

    it("Should Compute block XOR Correctly", async () => {
        let a= [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        let b = [0xE1, 0xE1, 0xE1, 0xE1, 0xE1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01];
        let sel = 0x01;
        let expected= [0xE1, 0xE1, 0xE1, 0xE1, 0xE1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01];
        await circuit.expectPass({ a: a, b: b, sel: sel }, { out: expected });
    });

});


describe("Z_I_UPDATE", () => {
    let circuit: WitnessTester<["Z", "V", "bit_val"], ["Z_new"]>;
  
    before(async () => {
      circuit = await circomkit.WitnessTester("XORBLOCK", {
        file: "aes-gcm/nistgmul",
        template: "Z_I_UPDATE",
        params: [16]
      });
      console.log("#constraints:", await circuit.getConstraintCount());
    });
    // msb is 1 so we xor the first byte with 0xE1
    it("Should Compute block XOR Correctly", async () => {
        let inputZ= [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        let inputV = [0xE1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01];
        let inputc = 0x00;
        let expected= [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        await circuit.expectPass({ Z: inputZ, V: inputV, bit_val: inputc }, { Z_new: expected });
    });

    it("Should Compute block XOR Correctly", async () => {
        let inputa = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        let inputb = [0xE1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01];
        let inputc = 0x01;
        const expected = [0xE1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01];
        await circuit.expectPass({ Z: inputa, V: inputb, bit_val: inputc }, { Z_new: expected });
    });
});