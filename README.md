<h1 align="center">
  AES-GCM circom circuits
</h1>

<div align="center">
  <a href="https://github.com/pluto/aes-gcm-circom/graphs/contributors">
    <img src="https://img.shields.io/github/contributors/pluto/aes-gcm-circom?style=flat-square&logo=github&logoColor=8b949e&labelColor=282f3b&color=32c955" alt="Contributors" />
  </a>
  <a href="https://github.com/pluto/aes-gcm-circom/actions/workflows/test.yaml">
    <img src="https://img.shields.io/badge/tests-passing-32c955?style=flat-square&logo=github-actions&logoColor=8b949e&labelColor=282f3b" alt="Tests" />
  </a>
  <a href="https://github.com/pluto/aes-gcm-circom/actions/workflows/lint.yaml">
    <img src="https://img.shields.io/badge/lint-passing-32c955?style=flat-square&logo=github-actions&logoColor=8b949e&labelColor=282f3b" alt="Lint" />
  </a>
</div>

## Overview

This repository contains a (WIP) implementation of [AES-GCM](https://web.cs.ucdavis.edu/~rogaway/ocb/gcm.pdf) in Circom. These circuits fork the underconstrained AES-GCM-SIV circuits from electron labs.

## Design Documents

- [Miro board](https://miro.com/app/board/uXjVKs-YCfM=/)
- [AES-GCM deep dive](https://gist.github.com/thor314/53cdab54aaf16bdafd5ac936d5447eb8)

## Getting Started

### Prerequisites

To use this repo, you need to install the `just` command runner:

```sh
cargo install just
# or use cargo binstall for fast install:
cargo binstall -y just

# install dependencies
just install
```

## Usage

### Generate AES witness values
Generate json witnesses and an AES proof to populate the `inputs` dir: `just witness`.

### Testing

#### End-2-end testing
Test that the witnesses in inputs are valid using the build/**/generate_witness.js circom artifact:
Run the `generate_witness.js` script:

### Unit testing with circomkit
Test witnesses are valid by writing tests in circomkit by running:
`just circom-test`

## Testing Circom
Example commands for using circom-kit
```
just circom-test # test all circom tests 
just circom-testg TESTNAME # test a named test

# also see:
`npx circomkit`: circomkit commands
`npx circomkit compile <circuit>`: equiv to `circom --wasm ...`
`npx circomkit witness <circuit> <witness.json>`: equiv to call generate_witness.js
```

The tests run by `circomkit` are are specified in `circuits.json` and `.mocharc.json`.

## Browser Execution Demo
To prove an AES execution with the witness files generated above:

Install node, circom, and set up the directory:

TODO(TK 2024-08-10): Move this to justfile

```sh
# install node
# setup js
cd client && npm install
cd client && npm start

# add build symlink
cd client/static && ln -s ../../build build

# install circom and snarkjs
git clone https://github.com/iden3/circom.git
cargo build --release
cargo install --path circom
npm install -g snarkjs@latest
```

```sh
# compile circuits
mkdir build

circom --wasm --sym --r1cs --output ./build ./circuits/aes/gcm_siv_dec_2_keys_test.circom

# generate trusted setup
# NOTE: This is currently unused because the rust zkey parser is horrible. 

pushd build 
curl "https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_10.ptau" --output 'powersOfTau28_hez_final_10.ptau' 
# we just did this:
curl "https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_19.ptau" --output 'powersOfTau28_hez_final_19.ptau' 
popd

SJS_BIN=$(dirname $(npm list -g --depth=0 | head -n 1)); SJS_BIN+="/bin/snarkjs"

node $SJS_BIN groth16 setup ./build/gcm_siv_dec_2_keys_test.r1cs ./build/powersOfTau28_hez_final_19.ptau ./build/test_0000.zkey

# test circuit
circom --wasm --sym --r1cs --output ./build ./circuits/aes/tiny.circom

snarkjs zkey new ./build/tiny.r1cs ./build/powersOfTau28_hez_final_10.ptau ./build/tiny.zkey
```

## License

Licensed under the Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)

## Contributing

We welcome contributions to our open-source projects. If you want to contribute or follow along with contributor discussions, join our [main Telegram channel](https://t.me/pluto_xyz/1) to chat about Pluto's development.

Our contributor guidelines can be found in [CONTRIBUTING.md](./CONTRIBUTING.md). A good starting point is issues labelled 'bounty' in our repositories.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the Apache-2.0 license, shall be licensed as above, without any additional terms or conditions.
