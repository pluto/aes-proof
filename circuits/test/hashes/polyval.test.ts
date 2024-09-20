import { WitnessTester } from "circomkit";
import { bitArrayToHex, circomkit, hexToBitArray } from "../common";
import { assert } from "chai";

// https://datatracker.ietf.org/doc/html/rfc8452#appendix-A
const H = hexToBitArray("25629347589242761d31f826ba4b757b");
const X1 = "4f4f95668c83dfb6401762bb2d01a262";
const X2 = "d1a24ddd2721d006bbe45f20d3c9f362";
const M = hexToBitArray(X1.concat(X2));
const EXPECT = "f7a3b47b846119fae5b7866cf5e5b77e";
// generated with rust-crypto
const EXPECT_2 = "cedac64537ff50989c16011551086d77";

// these take a long time (15s for the both), leave commented for until we can optimize these
// describe("POLYVAL_HASH_1", () => {
//   let circuit: WitnessTester<["msg", "H"], ["out"]>;

//   before(async () => {
//     circuit = await circomkit.WitnessTester(`polyval`, {
//       file: "aes-gcm/polyval",
//       template: "POLYVAL",
//       params: [2],
//     });
//     // console.log("#constraints:", await circuit.getConstraintCount());
//   });

//   it("POLYVAL 1", async () => {
//     const input = { msg: M, H: H };
//     const _res = await circuit.compute(input, ["out"]);
//     const result = bitArrayToHex(
//       (_res.out as number[][])[0].map((bit) => Number(bit))
//     )
//     // console.log("expect: ", EXPECT, "\nresult: ", result);
//     assert.equal(result, EXPECT);
//   });
// });

// describe("POLYVAL_HASH_2", () => {
//   let circuit: WitnessTester<["msg", "H"], ["out"]>;

//   before(async () => {
//     circuit = await circomkit.WitnessTester(`polyval`, {
//       file: "aes-gcm/polyval",
//       template: "POLYVAL",
//       params: [1],
//     });
//     // console.log("#constraints:", await circuit.getConstraintCount());
//   });

//   it("POLYVAL 2", async () => {
//     const M = hexToBitArray(X1);
//     const input = { msg: M, H: H };
//     const _res = await circuit.compute(input, ["out"]);
//     // console.log(bitArrayToHex((_res.out as number[][])[0]));
//     const result = bitArrayToHex(
//       (_res.out as number[][])[0].map((bit) => Number(bit))
//     );
//     // console.log("expect: ", EXPECT_2, "\nresult: ", result);
//     assert.equal(result, EXPECT_2);
//   });
// });
