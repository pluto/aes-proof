use aes::{
    cipher::{BlockEncrypt, InnerIvInit, KeyInit, KeyIvInit, StreamCipher, StreamCipherCore},
    Aes128, Aes256,
};
use aes_gcm::{
    aead::{generic_array::GenericArray, Aead, NewAead, Payload},
    Aes128Gcm, Aes256Gcm,
};
use cipher::consts::U16;
use ctr;
use ghash;
use hex;

type Ctr32BE<Aes128> = ctr::CtrCore<Aes128, ctr::flavors::Ctr32BE>;
type Aes256Ctr32BE = ctr::Ctr32BE<Aes256>;
type Block = GenericArray<u8, U16>;
type Aes128Ctr32BE = ctr::Ctr32BE<aes::Aes128>; // Note: Ctr32BE is used in AES GCM

pub enum CipherMode {
    Vanilla, // no IV Here
    Ctr256,
    GcmSiv,
    GCM256,
    Ctr128,
}

use crate::{make_nonce, make_tls13_aad, Witness};

const KEY_ASCII: &str = "1111111111111111"; // 16 bytes
const IV_ASCII: &str = "111111111111"; // 12 bytes
const MESSAGE: &str = "test000000000000";
const KEY_BYTES: [u8; 16] = [
    0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31,
];
const KEY_BYTES_256: [u8; 32] = [
    0x01, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x00, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x00, 0x0,
    0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x00, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
];
// test ascii
const MESSAGE_BYTES: [u8; 16] = [
    0x74, 0x65, 0x73, 0x74, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
];
const MESSAGE_BYTES_256: [u8; 16] = [
    0x74, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
];

// 765697b2244f246112a0d551aba59013a51e2eb57a229b92be46bf4e1e1c2068
// 85a01b63025ba19b7fd3ddfc033b3e76c9eac6fa700942702e90862383c6c366

// The TLS version converts the 12-byte IV into 16 bytes by padding with 0001.
const IV_BYTES: [u8; 16] = [
    0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x0, 0x0, 0x0,
    0x01, // GCM fills it out like this (when the IV is 12 bytes)
];
const IV_BYTES_256: [u8; 16] = [
    0x3, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
    // This matches the other impl passed in 12 bytes.
    // This is how GCM implements it.
    0x0, 0x0, 0x0, 0x1,
];

const IV_BYTES_SHORT: [u8; 12] = [
    0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31,
];
const IV_BYTES_SHORT_256: [u8; 12] = [0x3, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0];

const SIV_AAD: [u8; 16] = [
    0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
];
fn encrypt_tls(message: &[u8], key: &[u8], iv: &[u8], seq: u64) -> Vec<u8> {
    let total_len = message.len() + 1 + 16;
    let aad = make_tls13_aad(total_len);
    let fixed_iv = iv[..12].try_into().unwrap();
    // let fixed_key = key[..16].try_into().unwrap();
    let nonce = make_nonce(fixed_iv, seq); // hmmmm.

    println!(
        "ENC: msg={:?}, msg_len={:?}, seq={:?}",
        hex::encode(message),
        message.len(),
        seq
    );
    println!(
        "ENC: iv={:?}, dec_key={:?}",
        hex::encode(iv),
        hex::encode(key)
    );
    println!(
        "ENC: nonce={:?}, aad={:?}",
        hex::encode(nonce),
        hex::encode(aad)
    );

    let mut payload = Vec::with_capacity(total_len);
    payload.extend_from_slice(message);
    // payload.push(0x17);  // Very important, encrypted messages must have the type appended.

    let aes_payload = Payload {
        msg: &payload,
        aad: &[], // empty aad ??
    };

    let cipher = Aes128Gcm::new_from_slice(key).unwrap();
    let nonce = GenericArray::from_slice(iv);
    cipher
        .encrypt(nonce, aes_payload)
        .expect("error generating ct")
}


pub fn aes_witnesses(cipher_mode: CipherMode) -> Witness {
    // NOTES on AES
    // - AES-GCM, the authentication is a 16 byte string appended to the ciphertext.
    // - AES-GCM auth tag is encrypted at the end.
    // - AES-GCM the AAD only effects the auth tag
    // - AES-GCM-SIV, AAD impacts all ciphertext.
    // - AES is processed in 16 byte chunks. The chunks are then appended together.
    // - AES-CTR is a subset of GCM with some adjustments to IV prep (16 bytes)
    // - AES-GCM can be decrypted by AES-CTR, by skipping the auth tag and setting up the IV correctly.

    // Base ASCII versions using TLS encryption.
    let ct = encrypt_tls(
        MESSAGE.as_bytes(),
        KEY_ASCII.as_bytes(),
        IV_ASCII.as_bytes(),
        1,
    );
    println!(
        "ENC: cipher_text={:?}, cipher_len={:?}",
        hex::encode(ct.clone()),
        ct.len()
    );
    let key = GenericArray::from(KEY_BYTES);
    let key_256 = GenericArray::from(KEY_BYTES_256);
    let iv = GenericArray::from(IV_BYTES);
    let mut block = GenericArray::from(MESSAGE_BYTES);
    let mut block_256 = GenericArray::from(MESSAGE_BYTES_256);

    let cipher_text = match cipher_mode {
        CipherMode::Vanilla => {
            let cipher = Aes128::new(&key);
            cipher.encrypt_block(&mut block);
            block.to_vec()
        }
        CipherMode::Ctr256 => {
            // AES CTR 256, adjusted to match GCM. ✅, matches AES-256-GCM impl
            let mut cipher_256 = Aes256Ctr32BE::new(&key_256, &IV_BYTES_256.into());
            let mut tag_mask_256 = Block::default();

            cipher_256.apply_keystream(&mut tag_mask_256);
            cipher_256.apply_keystream(&mut block_256);
            block_256.to_vec()
        }
        CipherMode::GcmSiv => {
            // AES GCM SIV, WOO MATCHES CIRCOM!! ✅
            use aes_gcm_siv::{
                aead::{Aead, Payload as SIVPayload},
                Aes256GcmSiv,
            };
            let cipher = Aes256GcmSiv::new_from_slice(&key_256).unwrap();
            let nonce = GenericArray::from_slice(&IV_BYTES_SHORT_256);
            let aes_payload = SIVPayload {
                msg: &MESSAGE_BYTES_256,
                aad: &SIV_AAD,
            };
            let ciphertext_siv = cipher
                .encrypt(nonce, aes_payload)
                .expect("error generating ct");
            println!(
                "AES GCM 256 SIV: ct={:?}, bytes={:?}",
                hex::encode(ciphertext_siv.clone()),
                ciphertext_siv
            );
            ciphertext_siv.to_vec()
        }
        CipherMode::GCM256 => {
            // Standard AES 256 GCM
            let cipher = Aes256Gcm::new_from_slice(&key_256).unwrap();
            let nonce = GenericArray::from_slice(&IV_BYTES_SHORT_256);
            let aes_payload = Payload {
                msg: &MESSAGE_BYTES_256,
                aad: &SIV_AAD,
            };
            let ct = cipher
                .encrypt(nonce, aes_payload)
                .expect("error generating ct");
            ct.to_vec()
        }
        CipherMode::Ctr128 => {
            // AES CTR 128, adjusted to match GCM. ✅, matches AES-128-GCM impl
            let mut cipher = Aes128Ctr32BE::new(&key, &iv);
            let mut tag_mask = Block::default();
            cipher.apply_keystream(&mut tag_mask); // In AES-GCM, an empty mask is encrypted first.
            cipher.apply_keystream(&mut block);
            block.to_vec()
        }

    };

    // TODO: WTF is this
    // AES-GCM Duplication. NOTE: This is identical to section 246.
    // Init logic in AES-GCM. This standard procedure can be applied to the TLS IV.
    let mut ghash_iv = ghash::Block::default();
    ghash_iv[..12].copy_from_slice(&IV_BYTES_SHORT);
    ghash_iv[15] = 1;

    let inner_cipher = Aes128::new(&key);
    let mut ctr = Ctr32BE::inner_iv_init(&inner_cipher, &ghash_iv);
    let mut tag_mask = Block::default();

    ctr.write_keystream_block(&mut tag_mask);
    let mut buffer: Vec<u8> = Vec::new();
    buffer.extend_from_slice(MESSAGE.as_bytes());
    fn apply_keystream(ctr: Ctr32BE<&Aes128>, buf: &mut [u8]) {
        ctr.apply_keystream_partial(buf.into());
    }
    apply_keystream(ctr, &mut buffer);

    // WORKING!  The aes-ctr and aes-gcm now match.
    // TODO: Clean up these printlns
    println!(
        "INPUT iv={:?}, key={:?}",
        hex::encode(IV_BYTES),
        hex::encode(KEY_BYTES)
    );
    println!(
        "AES GCM IV={:?}, tm={:?}, ct={:?}",
        hex::encode(ghash_iv),
        hex::encode(tag_mask),
        hex::encode(buffer)
    );
    println!("AES CTR: ct={:?}", hex::encode(block));
    println!("AES CTR 256, 96 IV: ct={:?}", hex::encode(block));
    println!("AES GCM 256: ct={:?}", hex::encode(cipher_text.clone()));

    let key_out = key_256.to_vec();
    let ct_out = cipher_text.to_vec();

    // same for all modes, vanilla has no IV
    let iv_out = IV_BYTES_SHORT_256.to_vec();
    let pt_out = MESSAGE_BYTES_256.to_vec();

    Witness {
        key: key_out,
        iv: iv_out,
        ct: ct_out,
        pt: pt_out,
    }
}
