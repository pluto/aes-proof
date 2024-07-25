#![feature(trivial_bounds)]

mod proof;
mod witness;

use std::io;
use tokio;
// use ark_std::{end_timer, start_timer};

// // use ark_zkey;

#[tokio::main]
async fn main() -> io::Result<()> {
    let mut key: Vec<u8> = Vec::new();
    let mut iv: Vec<u8> = Vec::new();
    let mut ct: Vec<u8> = Vec::new();
    let mut pt: Vec<u8> = Vec::new();

    // // let mut file = File::open("./build/gcm_siv_dec_2_keys_test_0001.zkey").unwrap();
    // let mut reader = BufReader::new(file);

    // generate witness
    witness::aes_witnesses(&mut key, &mut iv, &mut ct, &mut pt);

    // log one of them
    println!(
        "proof gen: key={:?}, iv={:?}, ct={:?}, pt={:?}",
        key, iv, ct, pt
    );
    iv.extend_from_slice(&[0, 0, 0, 0]); // hackz for 128 bit iv

    // generate a proof
    proof::gen_proof_aes_gcm_siv(&key, &iv, &ct, &pt);

    Ok(())
}
