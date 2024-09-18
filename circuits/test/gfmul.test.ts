import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { padArrayTo64Bits, bitStringToHex, bitArrayToHex, circomkit, hexToBitArray, numberTo16Hex, numberToBitArray } from "./common";

const ZERO = hexToBitArray("0x000000000000000");
const BE_ONE = hexToBitArray("0x0000000000000001");
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
    const _res = await circuit.compute({ x: BE_ONE, y: BE_ONE }, ["out"]);
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
  let circuit_multiout: WitnessTester<["a", "b"], ["out", "out1"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`MUL`, {
      file: "aes-gcm/gfmul",
      template: "MUL",
    });

    circuit_multiout = await circomkit.WitnessTester(`MUL`, {
      file: "aes-gcm/gfmul",
      template: "MUL",
    });
    
  });

  it("GF_MUL test against rust baseline", async () => {
    function hexStringToByteArray(hexString: string) {
      // Ensure the string has an even number of characters
        if (hexString.length % 2 !== 0) {
            throw new Error('Hex string must have an even number of characters');
        }
    
        const byteArray = new Uint8Array(hexString.length / 2);
    
        for (let i = 0; i < byteArray.length; i++) {
            const byteValue = parseInt(hexString.substr(i * 2, 2), 16);
            if (isNaN(byteValue)) {
                throw new Error('Invalid hex string');
            }
            byteArray[i] = byteValue;
        }
    
        return byteArray;
    }
    
    function byteArrayToHex(byteArray: any) {
      return Array.from(byteArray, (byte: any) => {
          return ('0' + (byte & 0xFF).toString(16)).slice(-2);
      }).join('');
    }

    // Hex strings from rust, produce H, X, OUT
    // Q: Why does Mul not produce the same result? 
    // 
    // THEORIES:
    //
    // 1. The implementation expects little endian? No, doesn't match.
    // 2. Bit reverse is the problem? No, bit reverse doesn't work. 
    // 3. Both at the same time? No. 
    //

    let h = "aae06992acbf52a3e8f4a96ec9300bd7";
    let x = "98e7247c07f0fe411c267e4384b0f600";

    let h_le = byteArrayToHex(hexStringToByteArray(h).reverse());
    let x_le = byteArrayToHex(hexStringToByteArray(x).reverse());

    // mul part 0 9451e1d8ab889f9f
    // mul part 1 651478762ae227e7
    // reversed mul part 0 298a871bd511f9f9
    // reversed mul part 1 a6281e6e5447e4e7

    let out_polyval = "be00cd3b842e11f4 5efcd5401c3d2b7d";
    let out_ghash = "90e87315fb7d4e1b 4092ec0cbfda5d7d"; // ghash

    // big endian hex vectors
    let lower_h = hexToBitArray(h.slice(0, 16)); 
    let upper_h = hexToBitArray(h.slice(16, 32));
    let lower_x = hexToBitArray(x.slice(0, 16));
    let upper_x = hexToBitArray(x.slice(16, 32));

    // little endian hex vectors
    let lower_h_le = hexToBitArray(h_le.slice(0, 16)); 
    let upper_h_le = hexToBitArray(h_le.slice(16, 32));
    let lower_x_le = hexToBitArray(x_le.slice(0, 16));
    let upper_x_le = hexToBitArray(x_le.slice(16, 32));

    let lower_out = hexToBitArray(out_ghash.slice(0, 16));
    let upper_out = hexToBitArray(out_ghash.slice(16, 32));

    // reversed output:
    // 918dff3ce165e4fb
    // 64637fcf3859793e
    // 
    // 651478762ae227e7
    // 9451e1d8ab889f9f
    let reverseBits = function(byte: any) {
      byte = ((byte & 0xF0) >> 4) | ((byte & 0x0F) << 4);
      byte = ((byte & 0xCC) >> 2) | ((byte & 0x33) << 2);
      byte = ((byte & 0xAA) >> 1) | ((byte & 0x55) << 1);
      return byte;
    }
    let reversed_lower_h = hexToBitArray(byteArrayToHex(hexStringToByteArray(h_le.slice(0, 16)).map(reverseBits)));
    let reversed_upper_h = hexToBitArray(byteArrayToHex(hexStringToByteArray(h_le.slice(16, 32)).map(reverseBits)));
    let reversed_lower_x = hexToBitArray(byteArrayToHex(hexStringToByteArray(x_le.slice(0, 16)).map(reverseBits)));
    let reversed_upper_x = hexToBitArray(byteArrayToHex(hexStringToByteArray(x_le.slice(16, 32)).map(reverseBits)));

    // console.log("original lower_h", lower_h);
    // console.log("reversed lower_h", reversed_lower_h);
    
    const witness = await circuit_multiout.compute({ a: [lower_h, upper_h], b: [lower_x, upper_x] }, ["out", "out1"])
    let result_lower = bitStringToHex(witness.out.valueOf().toString())
    let result_upper = bitStringToHex(witness.out1.valueOf().toString())
    console.log("mul part 0", result_lower);
    console.log("mul part 1", result_upper);
    console.log("reversed mul part 0", byteArrayToHex(hexStringToByteArray(result_lower).map(reverseBits)));
    console.log("reversed mul part 1", byteArrayToHex(hexStringToByteArray(result_upper).map(reverseBits)));

    assert.deepEqual(witness.out, lower_out);
    assert.deepEqual(witness.out1, upper_out);

  });

  it("GF_MUL 0", async () => {
    await circuit.expectPass({ a: [MAX, MAX], b: [ZERO, ZERO] }, { out: [ZERO, ZERO] });
  });

  it("GF_MUL 1", async () => {
    await circuit.expectPass({ a: [ZERO, BE_ONE], b: [ZERO, BE_ONE] }, { out: [BE_ONE, ZERO] });
  });

  it( "GF_MUL 2", async () => {
    const E1 = hexToBitArray("C200000000000000");
    const E2 = hexToBitArray("0000000000000001");
    await circuit.expectPass({ a: [ZERO, BE_ONE], b: [BE_ONE, ZERO] }, { out: [E1, E2] });
  });

  it("GF_MUL 3", async () => {
    const E1 = hexToBitArray("0x00000000006F2B00");
    await circuit.expectPass({ a: [ZERO, hexToBitArray("0x00000000000000F1")], b: [ZERO, hexToBitArray("0x000000000000BB00")] }, { out: [E1, ZERO] });
  });

  // TODO: This seems to be switched endianness. 

  // fn test_mul_4() {
  //   let x = U64x2(0xBB00 as u64, 0);
  //   let y = U64x2(0u64, 0xF1 as u64);
  //   let z = x.mul(y);
  //   // let x = 0x1111_1111_1111_1111 as u64;
  //   // let y = 0x1111_1111_1111_1111 as u64;
  //   println!("x*y: {:08X}, {:08X}", z.0, z.1);
  //   panic!()
  //   // x*y: U64x2(13979173243358019584, 1)
  //   //  0xC323456789ABCDEF, 1
  // }

  it("GF_MUL 4", async () => {
    const E1 = hexToBitArray("0x000000000043AA16");
    const f1 = hexToBitArray("0x00000000000000F1");
    const bb = hexToBitArray("0x000000000000BB00");
    await circuit.expectPass({ a: [bb, ZERO], b: [ZERO, f1] }, { out: [ZERO, E1] });
  });

  it("GF_MUL 5", async () => {
    const fives = hexToBitArray("0x5555555555555555");
    const rest = hexToBitArray("0x7A01555555555555");
    await circuit.expectPass({ a: [MAX, MAX], b: [MAX, MAX] }, { out: [fives, rest] });
  });
});
