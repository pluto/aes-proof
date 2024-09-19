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

describe("POLYVAL_HASH_1", () => {
  let circuit: WitnessTester<["msg", "H"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`polyval`, {
      file: "aes-gcm/polyval",
      template: "POLYVAL",
      params: [2],
    });
    // console.log("#constraints:", await circuit.getConstraintCount());
  });

  it("POLYVAL 1", async () => {
    const input = { msg: M, H: H };
    const _res = await circuit.compute(input, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[][])[0].map((bit) => Number(bit))
    )
    console.log("expect: ", EXPECT, "\nresult: ", result);
    assert.equal(result, EXPECT);
  });
});

describe("POLYVAL_HASH_2", () => {
  let circuit: WitnessTester<["msg", "H"], ["out"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`polyval`, {
      file: "aes-gcm/polyval",
      template: "POLYVAL",
      params: [1],
    });
    // console.log("#constraints:", await circuit.getConstraintCount());
  });

  it("POLYVAL 2", async () => {
    const M = hexToBitArray(X1);
    const input = { msg: M, H: H };
    const _res = await circuit.compute(input, ["out"]);
    const result = bitArrayToHex(
      (_res.out as number[][])[0].map((bit) => Number(bit))
    );
    console.log("expect: ", EXPECT, "\nresult: ", result);
    assert.equal(result, EXPECT);
  });
});

// ---- polyval_test_vector_2 stdout ----
// proc_block: Array([4F, 4F, 95, 66, 8C, 83, DF, B6, 40, 17, 62, BB, 2D, 01, A2, 62])
// add: self.0: 0000000000000000, self.1: 0000000000000000
// add: rhs.0: B6DF838C66954F4F, rhs.1: 62A2012DBB621740
// mul: self.0: B6DF838C66954F4F, self.1: 62A2012DBB621740
// mul: rhs.0: 7642925847936225, rhs.1: 7B754BBA26F8311D
// __v2: 9850FF3745C6DACE, __v3: 776D08511501169C
// finalize block: Array([0000000000000206, 0000000000000218, 0000000000000198, 0000000000000069, 0000000000000055, 0000000000000255, 0000000000000080, 0000000000000152, 0000000000000156, 0000000000000022, 0000000000000001, 0000000000000021, 0000000000000081, 0000000000000008, 0000000000000109, 0000000000000119])
// [CE, DA, C6, 45, 37, FF, 50, 98, 9C, 16, 01, 15, 51, 08, 6D, 77]
// thread 'polyval_test_vector_2' panicked at polyval/tests/lib.rs:46:5:
// explicit panic
// note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
