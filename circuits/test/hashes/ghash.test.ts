import { WitnessTester } from "circomkit";
import { circomkit } from "../common";



describe("GHASH", () => {
  let circuit: WitnessTester<["HashKey", "msg"], ["tag"]>;

  before(async () => {
    circuit = await circomkit.WitnessTester(`ghash`, {
      file: "aes-gcm/ghash",
      template: "GHASH",
      params: [2],
    });
    console.log("#constraints:", await circuit.getConstraintCount());
  });

  it("test ghash", async () => {
    // https://datatracker.ietf.org/doc/html/rfc8452#appendix-A
    const H = [0x25, 0x62, 0x93, 0x47, 0x58, 0x92, 0x42, 0x76, 0x1d, 0x31, 0xf8, 0x26, 0xba, 0x4b, 0x75, 0x7b];
    const X1 = [0x4f, 0x4f, 0x95, 0x66, 0x8c, 0x83, 0xdf, 0xb6, 0x40, 0x17, 0x62, 0xbb, 0x2d, 0x01, 0xa2, 0x62];
    const X2 = [0xd1, 0xa2, 0x4d, 0xdd, 0x27, 0x21, 0xd0, 0x06, 0xbb, 0xe4, 0x5f, 0x20, 0xd3, 0xc9, 0xf3, 0x62];
    const M = X1.concat(X2);
    const EXPECT = [0xbd, 0x9b, 0x39, 0x97, 0x04, 0x67, 0x31, 0xfb, 0x96, 0x25, 0x1b, 0x91, 0xf9, 0xc9, 0x9d, 0x7a];
    await circuit.expectPass({ HashKey: H, msg: M }, { tag: EXPECT });
  });
});




