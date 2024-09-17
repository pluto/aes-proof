import { assert } from "chai";
import { WitnessTester } from "circomkit";
import { circomkit, hexBytesToBigInt } from "./common";

describe("aes-gcm", () => {
  let circuit: WitnessTester<["key", "iv", "plainText", "aad"], ["cipherText", "tag"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`aes-gcm`, {
      file: "aes-gcm/aes-gcm",
      template: "AESGCM",
      params: [16],
    });
  });

  let key = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00];
  let plainText = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00];
  let iv = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00];
  let HashKey = [0x66,0xe9,0x4b,0xd4,0xef,0x8a,0x2c,0x3b,0x88,0x4c,0xfa,0x59,0xca,0x34,0x2b,0x2e];
  let aad = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00];
  let expected_output = [0x03,0x88,0xda,0xce,0x60,0xb6,0xa3,0x92,0xf3,0x28,0xc2,0xb9,0x71,0xb2,0xfe,0x78];

  it("should have correct output", async () => {
    const witness = await circuit.compute({ key: key, iv: iv, plainText: plainText, aad: aad }, ["cipherText", "authTag"])

    assert.deepEqual(witness.cipherText, hexBytesToBigInt(expected_output))
  });

});

// signal input key[16]; // 128-bit key
// signal input iv[12]; // IV length is 96 bits (12 bytes)
// signal input plainText[l];
// signal input additionalData[16]; // AAD length is 128 bits (16 bytes)

// K = 00000000000000000000000000000000
// P = 00000000000000000000000000000000
// IV = 000000000000000000000000
// H = 66e94bd4ef8a2c3b884cfa59ca342b2e
// Y0 = 00000000000000000000000000000001                                58E2FCCEFA7E3061367F1D57A4E7455A
// E(K, Y0) = 58e2fccefa7e3061367f1d57a4e7455a ==> This is our output?? 58E2FCCEFA7E3061367F1D57A4E7455A
// Y1 = 00000000000000000000000000000002
// E(K, Y1) = 0388dace60b6a392f328c2b971b2fe78
// X1 = 5e2ec746917062882c85b0685353deb7
// len(A)||len(C) = 00000000000000000000000000000080
// GHASH(H, A, C) = f38cbb1ad69223dcc3457ae5b6b0f885
// C = 0388dace60b6a392f328c2b971b2fe78
// T = ab6e47d42cec13bdf53a67b21257bddf






