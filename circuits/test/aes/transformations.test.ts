import { WitnessTester } from "circomkit";
import { circomkit } from "../common";

describe("AES Key Expansion Components", () => {
  describe("Rotate", () => {
    let circuit: WitnessTester<["bytes"], ["rotated"]>;

    it("should rotate correctly", async () => {
      circuit = await circomkit.WitnessTester(`Rotate`, {
        file: "aes-gcm/aes/key_expansion",
        template: "Rotate",
        params: [1, 4],
      });
      console.log("RotateWord #constraints:", await circuit.getConstraintCount());
      await circuit.expectPass({ bytes: [0x01, 0x12, 0x02, 0x30] }, { rotated: [0x12, 0x02, 0x30, 0x01] });
    });
  });

  describe("SubstituteWord", () => {
    let circuit: WitnessTester<["bytes"], ["substituted"]>;
    before(async () => {
      circuit = await circomkit.WitnessTester(`SubstituteWord`, {
        file: "aes-gcm/aes/key_expansion",
        template: "SubstituteWord",
      });
      console.log("SubstituteWord #constraints:", await circuit.getConstraintCount());
    });

    it("should substitute correctly", async () => {
      await circuit.expectPass({ bytes: [0x00, 0x10, 0x20, 0x30] }, { substituted: [0x63, 0xca, 0xb7, 0x04] });
    });
  });

  describe("RCon", () => {
    let circuit: WitnessTester<[], ["out"]>;

    async function generatePassCase(round: number, out: number[]) {
      circuit = await circomkit.WitnessTester(`RCon`, {
        file: "aes-gcm/aes/key_expansion",
        template: "RCon",
        params: [round]
      });
      console.log("RCon #constraints:", await circuit.getConstraintCount());

      await circuit.expectPass({}, { out: out });
    }

    it("should compute round constant correctly", async () => {
      await generatePassCase(1, [0x01, 0x00, 0x00, 0x00]);
      await generatePassCase(2, [0x02, 0x00, 0x00, 0x00]);
      await generatePassCase(10, [0x36, 0x00, 0x00, 0x00]);
    });
  });

  describe("XorWord", () => {
    let circuit: WitnessTester<["bytes1", "bytes2"], ["out"]>;
    before(async () => {
      circuit = await circomkit.WitnessTester(`XorWord`, {
        file: "aes-gcm/aes/key_expansion",
        template: "XorWord",
      });
      console.log("XorWord #constraints:", await circuit.getConstraintCount());
    });

    it("should XOR correctly", async () => {
      await circuit.expectPass(
        { bytes1: [0x0a, 0x0b, 0x0c, 0x0d], bytes2: [0x01, 0x02, 0x03, 0x04] },
        { out: [0x0b, 0x09, 0x0f, 0x09] }
      );
    });
  });
});

describe("XTimes2", () => {
  let circuit: WitnessTester<["in"], ["out"]>;
  it("should perform 2 times", async () => {
    circuit = await circomkit.WitnessTester(`XTimes2`, {
      file: "aes-gcm/aes/cipher",
      template: "XTimes2",
    });
    console.log("@XTimes2 #constraints:", await circuit.getConstraintCount());

    // 0x57 . 2 = 0xae
    await circuit.expectPass({ in: [1, 1, 1, 0, 1, 0, 1, 0] }, { out: [0, 1, 1, 1, 0, 1, 0, 1] });
    // 0x54 . 2 = 0xa8
    await circuit.expectPass({ in: [0, 0, 1, 0, 1, 0, 1, 0] }, { out: [0, 0, 0, 1, 0, 1, 0, 1] });
    // 0xae . 2 = 0x47
    await circuit.expectPass({ in: [0, 1, 1, 1, 0, 1, 0, 1] }, { out: [1, 1, 1, 0, 0, 0, 1, 0] });
    // 0x47 . 2 = 0x8e
    await circuit.expectPass({ in: [1, 1, 1, 0, 0, 0, 1, 0] }, { out: [0, 1, 1, 1, 0, 0, 0, 1] });
  });
});
describe("XTimes", () => {
  let circuit: WitnessTester<["in"], ["out"]>;
  it("should perform  xtimes", async () => {
    circuit = await circomkit.WitnessTester(`XTimes`, {
      file: "aes-gcm/aes/cipher",
      template: "XTimes",
      params: [0x13],
    });
    console.log("@XTimes2 #constraints:", await circuit.getConstraintCount());

    // 0x57 . 0x13 = 0xfe
    await circuit.expectPass({ in: [1, 1, 1, 0, 1, 0, 1, 0] }, { out: [0, 1, 1, 1, 1, 1, 1, 1] });
  });
});

describe("XTimes2 with XTimes", () => {
  let circuit: WitnessTester<["in"], ["out"]>;
  it("should perform 2 times with XTERMS", async () => {
    circuit = await circomkit.WitnessTester(`XTimes`, {
      file: "aes-gcm/aes/cipher",
      template: "XTimes",
      params: [0x2],
    });
    console.log("@XTimes2 #constraints:", await circuit.getConstraintCount());

    // 0x57 . 2 = 0xae
    await circuit.expectPass({ in: [1, 1, 1, 0, 1, 0, 1, 0] }, { out: [0, 1, 1, 1, 0, 1, 0, 1] });
    // 0x54 . 2 = 0xa8
    await circuit.expectPass({ in: [0, 0, 1, 0, 1, 0, 1, 0] }, { out: [0, 0, 0, 1, 0, 1, 0, 1] });
    // 0xae . 2 = 0x47
    await circuit.expectPass({ in: [0, 1, 1, 1, 0, 1, 0, 1] }, { out: [1, 1, 1, 0, 0, 0, 1, 0] });
    // 0x47 . 2 = 0x8e
    await circuit.expectPass({ in: [1, 1, 1, 0, 0, 0, 1, 0] }, { out: [0, 1, 1, 1, 0, 0, 0, 1] });
  });
});

describe("XTimes1 with XTimes", () => {
  let circuit: WitnessTester<["in"], ["out"]>;
  it("should perform 1 times with XTERMS", async () => {
    circuit = await circomkit.WitnessTester(`XTimes`, {
      file: "aes-gcm/aes/cipher",
      template: "XTimes",
      params: [0x1],
    });
    console.log("@XTimes2 #constraints:", await circuit.getConstraintCount());

    // 0x57 . 2 = 0xae
    await circuit.expectPass({ in: [1, 1, 1, 0, 1, 0, 1, 0] }, { out: [1, 1, 1, 0, 1, 0, 1, 0] });
    // 0x54 . 2 = 0xa8
    await circuit.expectPass({ in: [0, 0, 1, 0, 1, 0, 1, 0] }, { out: [0, 0, 1, 0, 1, 0, 1, 0] });
    // 0xae . 2 = 0x47
    await circuit.expectPass({ in: [0, 1, 1, 1, 0, 1, 0, 1] }, { out: [0, 1, 1, 1, 0, 1, 0, 1] });
    // 0x47 . 2 = 0x8e
    await circuit.expectPass({ in: [1, 1, 1, 0, 1, 0, 1, 0] }, { out: [1, 1, 1, 0, 1, 0, 1, 0] });
  });
});

describe("MixColumns", () => {
  it("s0 should compute correctly", async () => {
    let circuit: WitnessTester<["in"], ["out"]>;
    circuit = await circomkit.WitnessTester(`s0`, {
      file: "aes-gcm/aes/cipher",
      template: "S0",
      params: [],
    });
    console.log("@S0 #constraints:", await circuit.getConstraintCount());

    await circuit.expectPass({ in: [0xd4, 0xbf, 0x5d, 0x30] }, { out: 0x04 });
  });

  it("s1 should compute correctly", async () => {
    let circuit: WitnessTester<["in"], ["out"]>;
    circuit = await circomkit.WitnessTester(`s1`, {
      file: "aes-gcm/aes/cipher",
      template: "S1",
      params: [],
    });
    console.log("@S1 #constraints:", await circuit.getConstraintCount());

    await circuit.expectPass({ in: [0xd4, 0xbf, 0x5d, 0x30] }, { out: 0x66 });
  });

  it("s2 should compute correctly", async () => {
    let circuit: WitnessTester<["in"], ["out"]>;
    circuit = await circomkit.WitnessTester(`s2`, {
      file: "aes-gcm/aes/cipher",
      template: "S2",
      params: [],
    });
    console.log("@S2 #constraints:", await circuit.getConstraintCount());

    await circuit.expectPass({ in: [0xd4, 0xbf, 0x5d, 0x30] }, { out: 0x81 });
  });

  it("s3 should compute correctly", async () => {
    let circuit: WitnessTester<["in"], ["out"]>;
    circuit = await circomkit.WitnessTester(`s3`, {
      file: "aes-gcm/aes/cipher",
      template: "S3",
      params: [],
    });
    console.log("@S3 #constraints:", await circuit.getConstraintCount());

    await circuit.expectPass({ in: [0xd4, 0xbf, 0x5d, 0x30] }, { out: 0xe5 });
  });

  it("s4 should compute correctly", async () => {
    let circuit: WitnessTester<["state"], ["out"]>;
    circuit = await circomkit.WitnessTester(`MixColumns`, {
      file: "aes-gcm/aes/cipher",
      template: "MixColumns",
      params: [],
    });
    console.log("@MixColumns #constraints:", await circuit.getConstraintCount());
    const state = [
      [0xd4, 0xe0, 0xb8, 0x1e],
      [0xbf, 0xb4, 0x41, 0x27],
      [0x5d, 0x52, 0x11, 0x98],
      [0x30, 0xae, 0xf1, 0xe5],
    ];

    const out = [
      [0x04, 0xe0, 0x48, 0x28],
      [0x66, 0xcb, 0xf8, 0x06],
      [0x81, 0x19, 0xd3, 0x26],
      [0xe5, 0x9a, 0x7a, 0x4c],
    ];

    await circuit.expectPass({ state }, { out });
  });
});

describe("AddRoundKey", () => {
  let circuit: WitnessTester<["state", "roundKey"], ["newState"]>;
  it("should perform AddRoundKey", async () => {
    circuit = await circomkit.WitnessTester(`AddRoundKey`, {
      file: "aes-gcm/aes/cipher",
      template: "AddRoundKey",
    });

    // 0x57 . 2 = 0xae
    await circuit.expectPass(
      {
        state: [
          [4, 224, 72, 40],
          [102, 203, 248, 6],
          [129, 25, 211, 38],
          [229, 154, 122, 76],
        ],
        roundKey: [
          [160, 250, 254, 23],
          [136, 84, 44, 177],
          [35, 163, 57, 57],
          [42, 108, 118, 5],
        ],
      },
      {
        newState: [
          [164, 104, 107, 2],
          [156, 159, 91, 106],
          [127, 53, 234, 80],
          [242, 43, 67, 73],
        ],
      }
    );
  });
});

describe("SubBlock", () => {
  let circuit: WitnessTester<["state"], ["newState"]>;
  it("should perform SubBlock", async () => {
    circuit = await circomkit.WitnessTester(`SubBlock`, {
      file: "aes-gcm/aes/cipher",
      template: "SubBlock",
    });
    // 0x57 . 2 = 0xae
    await circuit.expectPass(
      {
        state: [
          [25, 160, 154, 233],
          [61, 244, 198, 248],
          [227, 226, 141, 72],
          [190, 43, 42, 8],
        ],
      },
      {
        newState: [
          [212, 224, 184, 30],
          [39, 191, 180, 65],
          [17, 152, 93, 82],
          [174, 241, 229, 48],
        ],
      }
    );
  });
});

describe("ShiftRows", () => {
  let circuit: WitnessTester<["state"], ["newState"]>;
  it("should perform ShiftRows", async () => {
    circuit = await circomkit.WitnessTester(`ShiftRows`, {
      file: "aes-gcm/aes/cipher",
      template: "ShiftRows",
      params: [],
    });
    // 0x57 . 2 = 0xae
    await circuit.expectPass(
      {
        state: [
          [212, 224, 184, 30],
          [39, 191, 180, 65],
          [17, 152, 93, 82],
          [174, 241, 229, 48],
        ],
      },
      {
        newState: [
          [212, 224, 184, 30],
          [191, 180, 65, 39],
          [93, 82, 17, 152],
          [48, 174, 241, 229],
        ],
      }
    );
  });
});
