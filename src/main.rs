mod witness;
mod proof;

use std::io;
use tokio;

// First two bytes of witness. 
// 
// 1,0,1,1 1,0,1,0  0,0,0,0,0,0,0,0

#[tokio::main]
async fn main() -> io::Result<()>  {
    let mut key: Vec<u8> = Vec::new();
    let mut iv: Vec<u8> = Vec::new();
    let mut ct: Vec<u8> = Vec::new();
    let mut pt: Vec<u8> = Vec::new();

    // PROCESS (converting AES-GCM to AES-CTR)
    // - Initialize the CTR by encrypting in an empty ciphertext (prepend to witness?)
    // - Extend the IV with 0001
    // - No worries about AAD, it only alters the GHASH. Just drop it. 
    // - Incorporate the sequence number into the last byte of the IV (after init)
    // - Strip the last 16 byte GHASH.
    // 
    // Then, the CTR circuit should be able to decrypt every byte
    witness::aes_witnesses(&mut key, &mut iv, &mut ct, &mut pt);

    println!("proof gen: key={:?}, iv={:?}, ct={:?}, pt={:?}", key, iv, ct, pt);
    iv.extend_from_slice(&[0,0,0,0]); // hackz for 128 bit iv
    proof::gen_proof_aes_gcm_siv(&key, &iv, &ct, &pt);

    // TLS Example Content
    // REQUEST:  GET (only a URL), POST (can include a JSON object)
    // 
    // GET / HTTP/1.0
    // host: localhost
    // accept-encoding: identity
    // connection: close
    // accept: */*
    // 

    // RESPONSE: 
    // 
    // HTTP/1.0 200 OK
    // content-length: 14
    // date: Thu, 18 Jul 2024 14:32:31 GMT

    // Hello, World!

    Ok(())
}