import { Circomkit, WitnessTester } from "circomkit";
import 'mocha';

export const circomkit = new Circomkit({
    verbose: false,
});

export { WitnessTester };
