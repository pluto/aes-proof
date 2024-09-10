import { WitnessTester } from "circomkit";
import { circomkit } from "./common";

describe("Increment", () => {
  let circuit: WitnessTester<["in"], ["out"]>;
  it("should increment the input", async () => {
    circuit = await circomkit.WitnessTester(`Increment`, {
      file: "aes-gcm/helper_functions",
      template: "Increment32",
    });
    let res = await circuit.expectPass(
      {
        in: Array(128).fill(0),
      },
      {
        out: [...Array(127).fill(0), 1],
      }
    );
  });
});

describe("Increment32Block", () => {
    let circuit: WitnessTester<["in"], ["out"]>;
    it("should increment the block input 0", async () => {
        circuit = await circomkit.WitnessTester(`Increment32Block`, {
            file: "aes-gcm/helper_functions",
            template: "Increment32Block",
        });
        await circuit.expectPass(
            {
                in: [
                    [0x00, 0x00, 0x00, 0x00],
                    [0x00, 0x00, 0x00, 0x00],
                    [0x00, 0x00, 0x00, 0x00],
                    [0x00, 0x00, 0x00, 0x00]
                ],
            },
            {
                out: [
                    [0x00, 0x00, 0x00, 0x00],
                    [0x00, 0x00, 0x00, 0x00],
                    [0x00, 0x00, 0x00, 0x00],
                    [0x00, 0x00, 0x00, 0x01]
                ],
            }
        );
    });
    it("should increment the block input 1", async () => {
        circuit = await circomkit.WitnessTester(`Increment32Block`, {
            file: "aes-gcm/helper_functions",
            template: "Increment32Block",
        });
        await circuit.expectPass(
            {
                in: [
                    [0x00, 0x00, 0x00, 0x00],
                    [0x00, 0x00, 0x00, 0x00],
                    [0x00, 0x00, 0x00, 0x00],
                    [0x00, 0x00, 0x00, 0x01]
                    ],
            },
            {
                out: [
                    [0x00, 0x00, 0x00, 0x00],
                    [0x00, 0x00, 0x00, 0x00],
                    [0x00, 0x00, 0x00, 0x00],
                    [0x00, 0x00, 0x00, 0x02]
                ],
            }
        );
    });
});

// describe("IncrementWord", () => {
//     let circuit: WitnessTester<["in"], ["out"]>;
//     it("should increment the word input", async () => {
//         circuit = await circomkit.WitnessTester(`Increment32Block`, {
//             file: "aes-gcm/helper_functions",
//             template: "IncrementWord",
//         });
//         await circuit.expectPass(
//             {
//                 in: [
//                     [0x00, 0x00, 0x00, 0x00],
//                 ],
//             },
//             {
//                 out: [
//                     [0x00, 0x00, 0x00, 0x01]
//                 ],
//             }
//         );
//     });
// });