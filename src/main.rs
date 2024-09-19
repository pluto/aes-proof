//! This generates witnesses to test circom artifacts in the `circuits` directory.

#![feature(trivial_bounds)]
#![allow(unused_imports)]
#![allow(unused_variables)]
#![allow(dead_code)]
#![allow(unreachable_code)]
#![allow(non_snake_case)]
#![allow(clippy::clone_on_copy)]
#![allow(unused_mut)]

use std::{io, io::Write};

use aes::{cipher::generic_array::GenericArray, Aes256};
use cipher::consts::U16;
use utils::make_json_witness;

mod consts;
mod proof;
mod utils;
mod witness;

/// Circom compilation artifacts
/// Must compile circom artifacts first if these aren't found.
const SIV_WTNS: &str = "./build/gcm_siv_dec_2_keys_test_js/gcm_siv_dec_2_keys_test.wasm";
const SIV_R1CS: &str = "./build/gcm_siv_dec_2_keys_test.r1cs";
const AES_256_CRT_WTNS: &str = "./build/aes_256_ctr_test_js/aes_256_ctr_test.wasm";
const AES_256_CRT_R1CS: &str = "./build/aes_256_ctr_test.r1cs";

pub type AAD = [u8; 5];
pub type Nonce = [u8; 12];

// convenience type aliases for AES-CTR, wrapping type aliases from `ctr` crate
pub(crate) type Ctr32BE<Aes128> = ctr::CtrCore<Aes128, ctr::flavors::Ctr32BE>;
pub(crate) type Aes256Ctr32BE = ctr::Ctr32BE<Aes256>;
pub(crate) type Aes128Ctr32BE = ctr::Ctr32BE<aes::Aes128>; // Note: Ctr32BE is used in AES GCM

/// AES 128-bit block
pub(crate) type Block = GenericArray<u8, U16>;

#[tokio::main]
async fn main() -> io::Result<()> {
    let mut witness = witness::aes_witnesses(witness::CipherMode::Vanilla).unwrap();
    witness.iv.extend_from_slice(&[0, 0, 0, 0]);

    make_json_witness(&witness, witness::CipherMode::Vanilla).unwrap();

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    // Test the AES-GCM-SIV circuit (from electron labs)
    #[tokio::test]
    async fn test_aes_gcm_siv() {
        // generate witness
        let mut witness = witness::aes_witnesses(witness::CipherMode::GcmSiv).unwrap();

        // log one of them
        println!(
            "proof gen: key={:?}, iv={:?}, ct={:?}, pt={:?}",
            witness.key, witness.iv, witness.ct, witness.pt
        );

        // tls1.3 junk
        witness.iv.extend_from_slice(&[0; 4]);

        // generate proof
        proof::gen_proof_aes_gcm_siv(&witness, SIV_WTNS, SIV_R1CS);
    }

    // AES GCM multiple blocks of data
    // cargo test test_aes_gcm_blocks -- --show-output
    #[tokio::test]
    async fn test_aes_gcm_blocks() {
        use aes_gcm::{
            aead::{generic_array::GenericArray, Aead, NewAead, Payload},
            Aes128Gcm,
        };

        let test_key = [
            0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31,
            0x31, 0x31,
        ];
        let test_iv = [0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31];

        let message = String::from("testhello0000000testhello0000000");
        let aes_payload = Payload { msg: &message.as_bytes(), aad: &[] };

        let cipher = Aes128Gcm::new_from_slice(&test_key).unwrap();
        let nonce = GenericArray::from_slice(&test_iv);
        let ct = cipher.encrypt(nonce, aes_payload).expect("error generating ct");

        println!("key={}", hex::encode(test_key));
        println!("iv={}", hex::encode(test_iv));
        println!("msg={}", hex::encode(message));
        println!("ct={}", hex::encode(ct));
    }

    #[tokio::test]
    async fn test_ghash() {
        use ghash::{
            universal_hash::{KeyInit, UniversalHash},
            GHash,
        };
        use hex_literal::hex;

        // first bit is 1
        const H: [u8; 16] =   hex!("80000000000000000000000000000000");
        const X: [u8; 16] = hex!("80000000000000000000000000000000");


        let mut ghash = GHash::new(&H.into());
        ghash.update(&[X.into()]);
        let result = ghash.finalize();

        // last bit is 1
        const H_1: [u8; 16] = hex!("00000000000000000000000000000001");
        const X_1: [u8; 16] = hex!("00000000000000000000000000000001");
       
        let mut ghash2 = GHash::new(&H_1.into());
        ghash2.update(&[X_1.into()]);
        let result2 = ghash2.finalize();

        // test vector of pain
        const H_2: [u8; 16] = hex!("aae06992acbf52a3e8f4a96ec9300bd7");
        const X_2: [u8; 16] = hex!("98e7247c07f0fe411c267e4384b0f600");
        
        let mut ghash3 = GHash::new(&H_2.into());
        ghash3.update(&[X_2.into()]);
        let result3 = ghash3.finalize();

        println!("GHASH Test vector 1: {:?}", hex::encode(result.as_slice()));
        println!("GHASH Test vector 2: {:?}", hex::encode(result2.as_slice()));
        println!("GHASH Test vector 3: {:?}", hex::encode(result3.as_slice()));

        // println!("expected: {:?}", hex::encode(expected));

    }
}
