import { WitnessTester } from "circomkit";
import * as fs from 'fs';
import { circomkit } from "./common";


describe("AES 128 Enc", () => {
    let circuit: WitnessTester<["in"], ["out"]>;

    const witness_data = parseJsonFile("inputs/aes_128_enc_witness.json");

    before(async () => {
        circuit = await circomkit.WitnessTester(`aes_128_enc`, {
            file: "aes-gcm/aes_128_enc",
            template: "AES128Encrypt",
            // params: if the template has parameters
        });
        console.log("#constraints:", await circuit.getConstraintCount());
    });

    // TODO: Do we actually understand this?
    it("should have correct number of constraints", async () => {
        await circuit.expectConstraintCount(9920, true); /// should fail
    });

    // non-linear constraints: 9600 Where does the extra 320 constraints come from?
    // linear constraints: 0
    // public inputs: 0
    // private inputs: 1536
    // public outputs: 128
    // wires: 11137
    // labels: 22657

    let key1 = witness_data["k1"];
    let inputs = witness_data["in"];
    // let outputs = witness_data["out"];
    it("witness: in = [0,...]", async () => {
        await circuit.expectPass(
            { ks: key1 },
            { in: inputs },
        );
    });
});

function parseJsonFile(filePath: string): any {
    const fileContent = fs.readFileSync(filePath, 'utf-8');
    return JSON.parse(fileContent);
  }