use aes_gcm::{
    aead::{generic_array::GenericArray, Aead, NewAead, Payload},
    Aes128Gcm, Aes256Gcm,
};
use ghash;
use hex;

// Future code for decryption.
//
// #[repr(u8)]
// enum ContentType {
//     ChangeCipherSpec = 0x14,
//     Alert = 0x15,
//     Handshake = 0x16,
//     ApplicationData = 0x17,
//     Heartbeat = 0x18,
//     Unknown(u8) = 0x0,
// }
//
// impl From<u8> for ContentType {
//     fn from(x: u8) -> Self {
//         match x {
//             0x14 => Self::ChangeCipherSpec,
//             0x15 => Self::Alert,
//             0x16 => Self::Handshake,
//             0x17 => Self::ApplicationData,
//             0x18 => Self::Heartbeat,
//             _ => Self::Unknown(x)
//         }
//     }
// }
//
// fn unpad_tls13(v: &mut Vec<u8>) -> ContentType {
//     loop {
//         match v.pop() {
//             Some(0) => {}
//             Some(content_type) => return ContentType::from(content_type),
//             None => return ContentType::Unknown(0),
//         }
//     }
// }

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
    payload.extend_from_slice(&message);
    // payload.push(0x17);  // Very important, encrypted messages must have the type appended.

    let aes_payload = Payload {
        msg: &payload,
        aad: &[], // empty aad ??
    };

    let cipher = Aes128Gcm::new_from_slice(&key).unwrap();
    let nonce = GenericArray::from_slice(&iv);
    let ciphertext = cipher
        .encrypt(nonce, aes_payload)
        .expect("error generating ct");

    ciphertext
}

pub fn aes_witnesses(
    key_out: &mut Vec<u8>,
    iv_out: &mut Vec<u8>,
    ct_out: &mut Vec<u8>,
    pt_out: &mut Vec<u8>,
) {
    // NOTES on AES
    // - AES-GCM, the authentication is a 16 byte string appended to the ciphertext.
    // - AES-GCM auth tag is encrypted at the end.
    // - AES-GCM the AAD only effects the auth tag
    // - AES-GCM-SIV, AAD impacts all ciphertext.
    // - AES is processed in 16 byte chunks. The chunks are then appended together.
    // - AES-CTR is a subset of GCM with some adjustments to IV prep (16 bytes)
    // - AES-GCM can be decrypted by AES-CTR, by skipping the auth tag and setting up the IV correctly.

    // Base ASCII versions using TLS encryption.
    let key_ascii = "1111111111111111"; // 16 bytes
    let iv_ascii = "111111111111"; // 12 bytes
    let message = "test000000000000";
    let seq = 1;
    let ct = encrypt_tls(
        message.as_bytes(),
        key_ascii.as_bytes(),
        iv_ascii.as_bytes(),
        seq,
    );
    println!(
        "ENC: cipher_text={:?}, cipher_len={:?}",
        hex::encode(ct.clone()),
        ct.len()
    );

    let key_bytes = [
        0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31,
        0x31,
    ];
    let key_bytes_256 = [
        0x01, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x00, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x00,
        0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x00, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
    ];

    // test ascii
    let message_bytes = [
        0x74, 0x65, 0x73, 0x74, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
        0x30,
    ];
    let message_bytes_256 = [
        0x74, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
    ];

    // 765697b2244f246112a0d551aba59013a51e2eb57a229b92be46bf4e1e1c2068
    // 85a01b63025ba19b7fd3ddfc033b3e76c9eac6fa700942702e90862383c6c366

    // TODO: The tls version converting the 12 byte IV into 16 bytes by badding with 0001.
    let iv_bytes = [
        0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 
        0x0, 0x0, 0x0, 0x01, // GCM fills it out like this (when the IV is 12 bytes)
    ];
    let iv_bytes_256 = [
        0x3, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
        // Fascinating... this matches the other impl passed in 12 bytes.
        // I guess that makes sense, that is how GCM implements it.
        0x0, 0x0, 0x0, 0x1,
    ];

    let iv_bytes_short = [
        0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31,
    ];
    let iv_bytes_short_256 = [0x3, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0];

    let siv_aad = [
        0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
    ];

    use aes::cipher::{
        generic_array::GenericArray, BlockEncrypt, KeyInit, KeyIvInit, StreamCipher,
    };
    use aes::{Aes128, Aes256};
    use ctr;

    type Block = GenericArray<u8, U16>;
    let key = GenericArray::from(key_bytes);
    let key_256 = GenericArray::from(key_bytes_256);
    let iv = GenericArray::from(iv_bytes);

    // Base AES Cipher (no CTR), unused, demo.
    let cipher = Aes128::new(&key);
    let mut block_no_ctr = GenericArray::from(message_bytes);
    cipher.encrypt_block(&mut block_no_ctr);

    // AES CTR 256, adjusted to match GCM. ✅, matches AES-256-GCM impl
    type Aes256Ctr32BE = ctr::Ctr32BE<Aes256>;
    let mut cipher_256 = Aes256Ctr32BE::new(&key_256.into(), &iv_bytes_256.into());
    let mut block_256 = GenericArray::from(message_bytes_256);
    let mut tag_mask_256 = Block::default();
    cipher_256.apply_keystream(&mut tag_mask_256);
    cipher_256.apply_keystream(&mut block_256);

    // AES GCM SIV, WOO MATCHES CIRCOM!! ✅
    use aes_gcm_siv::{
        aead::{Aead, Payload as SIVPayload},
        Aes256GcmSiv,
    };
    let cipher = Aes256GcmSiv::new_from_slice(&key_256).unwrap();
    let nonce = GenericArray::from_slice(&iv_bytes_short_256);
    let aes_payload = SIVPayload {
        msg: &message_bytes_256,
        aad: &siv_aad,
    };
    let ciphertext_siv = cipher
        .encrypt(nonce, aes_payload)
        .expect("error generating ct");

    // Standard AES 256 GCM
    let cipher = Aes256Gcm::new_from_slice(&key_256).unwrap();
    let nonce = GenericArray::from_slice(&iv_bytes_short_256);
    let aes_payload = Payload {
        msg: &message_bytes_256,
        aad: &[],
    };
    let ciphertext = cipher
        .encrypt(nonce, aes_payload)
        .expect("error generating ct");

    // AES CTR 128, adjusted to match GCM. ✅, matches AES-128-GCM impl
    type Aes128Ctr32BE = ctr::Ctr32BE<aes::Aes128>; // Note: Ctr32BE is used in AES GCM
    let mut cipher = Aes128Ctr32BE::new(&key.into(), &iv.into());
    let mut block = GenericArray::from(message_bytes);
    let mut tag_mask = Block::default();
    cipher.apply_keystream(&mut tag_mask); // In AES-GCM, an empty mask is encrypted first.
    cipher.apply_keystream(&mut block);
    // let mut repeat_block = GenericArray::from(message_bytes);
    // cipher.apply_keystream(&mut repeat_block)

    // AES-GCM Duplication. NOTE: This is identical to section 246.
    // Init logic in AES-GCM. This standard procedure can be applied to the TLS IV.
    let mut ghash_iv = ghash::Block::default();
    ghash_iv[..12].copy_from_slice(&iv_bytes_short);
    ghash_iv[15] = 1;

    use aes::cipher::{InnerIvInit, StreamCipherCore};
    use cipher::consts::U16;

    type Ctr32BE<Aes128> = ctr::CtrCore<Aes128, ctr::flavors::Ctr32BE>;
    let inner_cipher = Aes128::new(&key);
    let mut ctr = Ctr32BE::inner_iv_init(&inner_cipher, &ghash_iv);
    let mut tag_mask = Block::default();

    ctr.write_keystream_block(&mut tag_mask);
    let mut buffer: Vec<u8> = Vec::new();
    buffer.extend_from_slice(message.as_bytes());
    fn apply_keystream(ctr: Ctr32BE<&Aes128>, buf: &mut [u8]) {
        ctr.apply_keystream_partial(buf.into());
    }
    apply_keystream(ctr, &mut buffer);

    // WORKING!  The aes-ctr and aes-gcm now match.
    println!(
        "INPUT iv={:?}, key={:?}",
        hex::encode(iv_bytes),
        hex::encode(key_bytes)
    );
    println!("AES NO CTR: ct={:?}", hex::encode(block_no_ctr));
    println!(
        "AES GCM IV={:?}, tm={:?}, ct={:?}",
        hex::encode(ghash_iv),
        hex::encode(tag_mask),
        hex::encode(buffer)
    );
    println!("AES CTR: ct={:?}", hex::encode(block));
    println!("AES CTR 256, 96 IV: ct={:?}", hex::encode(block_256));
    println!("AES GCM 256: ct={:?}", hex::encode(ciphertext.clone()));
    println!(
        "AES GCM 256 SIV: ct={:?}, bytes={:?}",
        hex::encode(ciphertext_siv.clone()),
        ciphertext_siv
    );

    ct_out.extend_from_slice(&ciphertext_siv);
    key_out.extend_from_slice(&key_256);
    iv_out.extend_from_slice(&iv_bytes_short_256);
    pt_out.extend_from_slice(&message_bytes_256);
}
