# Demo of AES Proving

Go through installation steps below to prepare build artifacts. 

Generate various witnesses & an aes proof
`cargo run --release`

## TODO
The goal of this repo is to create a proof-of-concept for our AES requests. 

1. Verify circuits with aes-256-ctr
2. Configure circuits to work for 128 bit
3. Generate TLS specific witness conversion for aes-128-ctr
4. Performance test with snarkjs 
5. Probably add a wasm target
6. Potentially rewrite in Halo2 for smaller PK/VK
7. Concerningly, these proofs verify with invalid ciphertext (only output is invalid)


## Installation

*install circom*

`git clone https://github.com/iden3/circom.git`

`cargo build --release`

`cargo install --path circom`

*install snarkjs*

`npm install -g snarkjs@latest`

*compile circuits*

`mkdir build`

`circom --wasm --sym --r1cs --output ./build ./circuits/gcm_siv_dec_2_keys_test.circom`

*generate trusted setup*
NOTE: This is currently unused because the rust zkey parser is horrible. 

`cd build && curl "https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_10.ptau" --output './build/powersOfTau28_hez_final_10.ptau' && cd ..`

`cd build && curl "https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_19.ptau" --output './build/powersOfTau28_hez_final_19.ptau' && cd ..`

`SJS_BIN=$(dirname $(npm list -g --depth=0 | head -n 1)); SJS_BIN+="/bin/snarkjs"`

`node $SJS_BIN groth16 setup ./build/gcm_siv_dec_2_keys_test.r1cs ./build/powersOfTau28_hez_final_19.ptau ./build/test_0000.zkey`

*test circuit*

`circom --wasm --sym --r1cs --output ./build ./circuits/tiny.circom`

`snarkjs zkey new ./build/tiny.r1cs ./build/powersOfTau28_hez_final_10.ptau ./build/tiny.zkey`