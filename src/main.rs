#![feature(trivial_bounds)]

use std::io;

use ark_circom::CircomBuilder;
use ark_ec::pairing::Pairing;

mod proof;
mod witness;


// You have to compile circom artifacts first if these aren't found.
// should I commit them?
const SIV_WTNS: &str = "./build/gcm_siv_dec_2_keys_test_js/gcm_siv_dec_2_keys_test.wasm";
const SIV_R1CS: &str = "./build/gcm_siv_dec_2_keys_test.r1cs";

const AES_256_CRT_WTNS: &str = "./build/aes_256_ctr_test_js/aes_256_ctr_test.wasm";
const AES_256_CRT_R1CS: &str = "./build/aes_256_ctr_test.r1cs";


pub struct Witness {
    pub key: Vec<u8>,
    pub iv: Vec<u8>,
    pub ct: Vec<u8>,
    pub pt: Vec<u8>,
}

#[tokio::main]
async fn main() -> io::Result<()> {
    // aes_gcm_siv_test
    // aes_gcm_siv_test().await?;

    // plain aes_ctr test
    aes_256ctr_test().await?;
    Ok(())
}

async fn aes_gcm_siv_test() -> io::Result<()> {
    // generate witness
    let mut witness = witness::aes_witnesses(witness::CipherMode::GcmSiv);

    // log one of them
    println!(
        "proof gen: key={:?}, iv={:?}, ct={:?}, pt={:?}",
        witness.key, witness.iv, witness.ct, witness.pt
    );
    witness.iv.extend_from_slice(&[0, 0, 0, 0]); // hackz for 128 bit iv, Ask Tracy about this

    // generate a proof
    proof::gen_proof_aes_gcm_siv(&witness, SIV_WTNS, SIV_R1CS);
    Ok(())
}

async fn aes_256ctr_test() -> io::Result<()> {
    let mut witness = witness::aes_witnesses(witness::CipherMode::Ctr256);

    // log one of them
    println!(
        "proof gen: key={:?}, iv={:?}, ct={:?}, pt={:?}",
        witness.key, witness.iv, witness.ct, witness.pt
    );
    witness.iv.extend_from_slice(&[0, 0, 0, 0]); // hackz for 128 bit iv

    // generate a proof
    proof::gen_proof_aes_gcm_siv(&witness, AES_256_CRT_WTNS, AES_256_CRT_R1CS);

    Ok(())
}

// Convert bytes to bits (process in big endian order)
fn push_bytes_as_bits<T: Pairing>(
    mut builder: CircomBuilder<T>,
    field: &str,
    bytes: &[u8],
) -> CircomBuilder<T> {
    for byte in bytes {
        for i in 0..8 {
            let bit = (byte >> (7 - i)) & 1;
            builder.push_input(field, bit as u64);
        }
    }

    builder
}

pub fn make_nonce(iv: [u8; 12], seq: u64) -> [u8; 12] {
    let mut nonce = [0u8; 12];
    nonce[4..].copy_from_slice(&seq.to_be_bytes());

    nonce.iter_mut().zip(iv.iter()).for_each(|(nonce, iv)| {
        *nonce ^= *iv;
    });

    nonce
}

fn make_tls13_aad(len: usize) -> [u8; 5] {
    [
        0x17, // ContentType::ApplicationData
        0x3,  // ProtocolVersion (major)
        0x3,  // ProtocolVersion (minor)
        (len >> 8) as u8,
        len as u8,
    ]
}
