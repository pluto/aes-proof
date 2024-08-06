# AES-GCM circom circuits
A (WIP) implementation of [AES-GCM](https://web.cs.ucdavis.edu/~rogaway/ocb/gcm.pdf) in Circom.


## Generate AES witnsess values
Generate witnesses and an AES proof:
`cargo run --release`

## Browser Execution Demo
To prove an AES execution with the witness files generated above:

Install node, circom, and set up the directory:
```sh
# install node

# setup js
cd client && npm install
cd client && npm start

# add build symlink
cd client/static && ln -s ../../build build


## Installation
# install circom
git clone https://github.com/iden3/circom.git

cargo build --release

cargo install --path circom

# install snarkjs
npm install -g snarkjs@latest
```

```sh
# compile circuits
mkdir build

circom --wasm --sym --r1cs --output ./build ./circuits/gcm_siv_dec_2_keys_test.circom

# generate trusted setup
NOTE: This is currently unused because the rust zkey parser is horrible. 

cd build && curl "https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_10.ptau" --output './build/powersOfTau28_hez_final_10.ptau' && cd ..

cd build && curl "https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_19.ptau" --output './build/powersOfTau28_hez_final_19.ptau' && cd ..

SJS_BIN=$(dirname $(npm list -g --depth=0 | head -n 1)); SJS_BIN+="/bin/snarkjs"

node $SJS_BIN groth16 setup ./build/gcm_siv_dec_2_keys_test.r1cs ./build/powersOfTau28_hez_final_19.ptau ./build/test_0000.zkey

# test circuit*
circom --wasm --sym --r1cs --output ./build ./circuits/tiny.circom

snarkjs zkey new ./build/tiny.r1cs ./build/powersOfTau28_hez_final_10.ptau ./build/tiny.zkey
```