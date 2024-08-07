use aes::{cipher::StreamCipherCore, Aes128};
use ark_bn254::Fr;
use ark_circom::CircomBuilder;
use ark_ec::pairing::Pairing;

use crate::{Ctr32BE, Nonce, AAD};

// TODO(TK 2024-08-06): test with test vectors at bottom of rfc 8452
// @devloper: do you know/couldyou find where make_nonce is specified in rfc8452?
//
/// construct the nonce from the `iv` and `seq` as specified in RFC 8452
/// https://www.rfc-editor.org/rfc/rfc8452

/// See TLS1.3
pub(crate) fn make_nonce(iv: [u8; 12], seq: u64) -> Nonce {
    let mut nonce = [0u8; 12];
    nonce[4..].copy_from_slice(&seq.to_be_bytes());

    nonce.iter_mut().zip(iv).for_each(|(nonce, iv)| {
        *nonce ^= iv;
    });

    nonce
}

/// tls 1.3 aad
pub(crate) fn make_tls13_aad(len: usize) -> AAD {
    [
        0x17, // ContentType::ApplicationData
        0x3,  // ProtocolVersion (major)
        0x3,  // ProtocolVersion (minor)
        (len >> 8) as u8,
        len as u8,
    ]
}

// TODO(TK 2024-08-06): @devloper, document and refactor for transparency
pub(crate) fn push_bytes_as_bits<T: Pairing>(
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

// convert bits to bytes
pub(crate) fn bits_to_u8(bits: &[u8]) -> u8 {
    bits.iter().rev().enumerate().fold(0, |acc, (i, &bit)| acc | ((bit & 1) << i))
}

pub(crate) fn parse_bit_from_field(j: &Fr) -> u8 {
    // TODO(TK 2024-08-06): move to lazy static to avoid duplication
    let ONE = Fr::from(1);
    let ZERO = Fr::from(0);

    if *j == ONE {
        1u8
    } else if *j == ZERO {
        0u8
    } else {
        panic!("results should be bits")
    }
}

pub(crate) fn apply_keystream(ctr: Ctr32BE<&Aes128>, buf: &mut [u8]) {
    ctr.apply_keystream_partial(buf.into());
}
