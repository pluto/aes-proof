import { WitnessTester } from "circomkit";
import { circomkit } from "../common";


describe("ToBlocks", () => {
  let circuit: WitnessTester<["stream"], ["blocks"]>;
  it("should convert stream to block", async () => {
    circuit = await circomkit.WitnessTester(`ToBlocks`, {
      file: "aes-gcm/aes/utils",
      template: "ToBlocks",
      params: [16],
    });
    console.log("@ToBlocks #constraints:", await circuit.getConstraintCount());

    await circuit.expectPass(
      {
        stream: [0x32, 0x88, 0x31, 0xe0, 0x43, 0x5a, 0x31, 0x37, 0xf6, 0x30, 0x98, 0x07, 0xa8, 0x8d, 0xa2, 0x34],
      },
      {
        blocks: [
          [
            [0x32, 0x43, 0xf6, 0xa8],
            [0x88, 0x5a, 0x30, 0x8d],
            [0x31, 0x31, 0x98, 0xa2],
            [0xe0, 0x37, 0x07, 0x34],
          ],
        ],
      }
    );
  });
  it("should pad 1 in block", async () => {
    circuit = await circomkit.WitnessTester(`ToBlocks`, {
      file: "aes-gcm/aes/utils",
      template: "ToBlocks",
      params: [15],
    });
    console.log("@EncryptCTR #constraints:", await circuit.getConstraintCount());

    await circuit.expectPass(
      {
        stream: [0x32, 0x88, 0x31, 0xe0, 0x43, 0x5a, 0x31, 0x37, 0xf6, 0x30, 0x98, 0x07, 0xa8, 0x8d, 0xa2],
      },
      {
        blocks: [
          [
            [0x32, 0x43, 0xf6, 0xa8],
            [0x88, 0x5a, 0x30, 0x8d],
            [0x31, 0x31, 0x98, 0xa2],
            [0xe0, 0x37, 0x07, 0x01],
          ],
        ],
      }
    );
  });
  it("should pad 0's in block", async () => {
    circuit = await circomkit.WitnessTester(`ToBlocks`, {
      file: "aes-gcm/aes/utils",
      template: "ToBlocks",
      params: [14],
    });
    console.log("@ToBLocks #constraints:", await circuit.getConstraintCount());

    await circuit.expectPass(
      {
        stream: [0x32, 0x88, 0x31, 0xe0, 0x43, 0x5a, 0x31, 0x37, 0xf6, 0x30, 0x98, 0x07, 0xa8, 0x8d],
      },
      {
        blocks: [
          [
            [0x32, 0x43, 0xf6, 0xa8],
            [0x88, 0x5a, 0x30, 0x8d],
            [0x31, 0x31, 0x98, 0x01],
            [0xe0, 0x37, 0x07, 0x00],
          ],
        ],
      }
    );
  });
  it("should generate enough blocks", async () => {
    circuit = await circomkit.WitnessTester(`ToBlocks`, {
      file: "aes-gcm/aes/utils",
      template: "ToBlocks",
      params: [17],
    });
    console.log("@ToBLocks #constraints:", await circuit.getConstraintCount());

    await circuit.expectPass(
      {
        stream: [0x32, 0x88, 0x31, 0xe0, 0x42, 0x5a, 0x31, 0x37, 0xf6, 0x30, 0x98, 0x07, 0xa8, 0x8d, 0xa2, 0x34, 0x12],
      },
      {
        blocks: [
          [
            [0x32, 0x42, 0xf6, 0xa8],
            [0x88, 0x5a, 0x30, 0x8d],
            [0x31, 0x31, 0x98, 0xa2],
            [0xe0, 0x37, 0x07, 0x34],
          ],
          [
            [0x12, 0x00, 0x00, 0x00],
            [0x01, 0x00, 0x00, 0x00],
            [0x00, 0x00, 0x00, 0x00],
            [0x00, 0x00, 0x00, 0x00],
          ],
        ],
      }
    );
  });
});


describe("ToStream", () => {
  let circuit: WitnessTester<["blocks"], ["stream"]>;
  it("should convert blocks to stream#1", async () => {
    circuit = await circomkit.WitnessTester(`ToStream`, {
      file: "aes-gcm/aes/utils",
      template: "ToStream",
      params: [1, 16],
    });
    console.log("@ToStream #constraints:", await circuit.getConstraintCount());

    await circuit.expectPass(
      {
        blocks: [
          [
            [0x32, 0x43, 0xf6, 0xa8],
            [0x88, 0x5a, 0x30, 0x8d],
            [0x31, 0x31, 0x98, 0xa2],
            [0xe0, 0x37, 0x07, 0x34],
          ],
        ],
      },
      {
        stream: [0x32, 0x88, 0x31, 0xe0, 0x43, 0x5a, 0x31, 0x37, 0xf6, 0x30, 0x98, 0x07, 0xa8, 0x8d, 0xa2, 0x34],
      }
    );
  });
  it("should convert blocks to stream#2", async () => {
    circuit = await circomkit.WitnessTester(`ToStream`, {
      file: "aes-gcm/aes/utils",
      template: "ToStream",
      params: [1, 15],
    });
    console.log("@ToStream #constraints:", await circuit.getConstraintCount());

    await circuit.expectPass(
      {
        blocks: [
          [
            [0x32, 0x43, 0xf6, 0xa8],
            [0x88, 0x5a, 0x30, 0x8d],
            [0x31, 0x31, 0x98, 0xa2],
            [0xe0, 0x37, 0x07, 0x01],
          ],
        ],
      },
      {
        stream: [0x32, 0x88, 0x31, 0xe0, 0x43, 0x5a, 0x31, 0x37, 0xf6, 0x30, 0x98, 0x07, 0xa8, 0x8d, 0xa2],
      }
    );
  });
  it("should convert multiple blocks to stream", async () => {
    circuit = await circomkit.WitnessTester(`ToStream`, {
      file: "aes-gcm/aes/utils",
      template: "ToStream",
      params: [2, 18],
    });
    console.log("@ToStream #constraints:", await circuit.getConstraintCount());

    await circuit.expectPass(
      {
        blocks: [
          [
            [0x32, 0x43, 0xf6, 0xa8],
            [0x88, 0x5a, 0x30, 0x8d],
            [0x31, 0x31, 0x98, 0xa2],
            [0xe0, 0x37, 0x07, 0x01],
          ],
          [
            [0x32, 0x43, 0xf6, 0xa8],
            [0x88, 0x5a, 0x30, 0x8d],
            [0x31, 0x31, 0x98, 0xa2],
            [0xe0, 0x37, 0x07, 0x01],
          ],
        ],
      },
      {
        stream: [
          0x32, 0x88, 0x31, 0xe0, 0x43, 0x5a, 0x31, 0x37, 0xf6, 0x30, 0x98, 0x07, 0xa8, 0x8d, 0xa2, 0x01, 0x32, 0x88,
        ],
      }
    );
  });
});
