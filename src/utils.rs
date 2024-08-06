use ark_circom::CircomBuilder;
use ark_ec::pairing::Pairing;

use crate::{Nonce, AAD};

// TODO(TK 2024-08-06): test with test vectors at bottom of rfc 8452
// @devloper: do you know/couldyou find where make_nonce is specified in rfc8452?
//
/// construct the nonce from the `iv` and `seq` as specified in RFC 8452
/// https://www.rfc-editor.org/rfc/rfc8452
pub(crate) fn make_nonce(iv: [u8; 12], seq: u64) -> Nonce {
    let mut nonce = [0u8; 12];
    nonce[4..].copy_from_slice(&seq.to_be_bytes());

    nonce.iter_mut().zip(iv).for_each(|(nonce, iv)| {
        *nonce ^= iv;
    });

    nonce
}

pub(crate) fn make_tls13_aad(len: usize) -> AAD {
    [
        0x17, // ContentType::ApplicationData
        0x3,  // ProtocolVersion (major)
        0x3,  // ProtocolVersion (minor)
        (len >> 8) as u8,
        len as u8,
    ]
}

// TODO(TK 2024-08-06): @devloper, document
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
