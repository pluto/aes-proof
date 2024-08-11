import { WitnessTester } from "circomkit";
import { circomkit } from "./common";

describe("NextRound", () => {
  let circuit: WitnessTester<["key", "round"], ["nextKey"]>;

  describe("NextRound", () => {
    before(async () => {
      circuit = await circomkit.WitnessTester(`NextRound_${4}_${4}`, {
        file: "aes-ctr/key_expansion",
        template: "NextRound",
        params: [4, 4],
      });
      console.log("#constraints:", await circuit.getConstraintCount());
    });

    it("should compute correctly", async () => {
      const key = [
        [0x2b, 0x7e, 0x15, 0x16],
        [0x28, 0xae, 0xd2, 0xa6],
        [0xab, 0xf7, 0x15, 0x88],
        [0x09, 0xcf, 0x4f, 0x3c],
      ];

      const expectedNextKey = [
        [0xa0, 0xfa, 0xfe, 0x17],
        [0x88, 0x54, 0x2c, 0xb1],
        [0x23, 0xa3, 0x39, 0x39],
        [0x2a, 0x6c, 0x76, 0x05],
      ];

      await circuit.expectPass({ key, round: 1 }, { nextKey: expectedNextKey });
    });
  });

  // describe("NextRound", () => {
  //   before(async () => {
  //     circuit = await circomkit.WitnessTester(`NextRound_${6}_${6}`, {
  //       file: "key_expansion",
  //       template: "NextRound",
  //       params: [6, 6],
  //     });
  //     console.log("#constraints:", await circuit.getConstraintCount());
  //   });

  //   it("should compute correctly for AES-192", async () => {
  //     const key = [
  //       [0x8e, 0x73, 0xb0, 0xf7],
  //       [0xda, 0x0e, 0x64, 0x52],
  //       [0xc8, 0x10, 0xf3, 0x2b],
  //       [0x80, 0x90, 0x79, 0xe5],
  //     ];

  //     const expectedNextKey = [
  //       [0x62, 0xf8, 0xea, 0xd2],
  //       [0x52, 0x2c, 0x6b, 0x7b],
  //       [0xfe, 0x0c, 0x91, 0xf7],
  //       [0x24, 0x02, 0xf5, 0xa5],
  //     ];

  //     await circuit.expectPass({ key, round: 1 }, { nextKey: expectedNextKey });
  //   });
  // });
});
