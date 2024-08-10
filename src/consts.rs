//! values borrowed from https://github.com/Electron-Labs/aes-circom/blob/master/test/gcm_siv_dec_2_keys.test.js#L7
// @devloper: document each const origin on call
pub(crate) const KEY_ASCII: &str = "1111111111111111"; // 16 bytes
pub(crate) const IV_ASCII: &str = "111111111111"; // 12 bytes
pub(crate) const MESSAGE: &str = "test000000000000";
pub(crate) const KEY_BYTES_128: [u8; 16] = [
    0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31,
];
pub(crate) const KEY_BYTES_256: [u8; 32] = [
    0x01, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x00, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x00, 0x0,
    0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x00, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
];
// test ascii
pub(crate) const MESSAGE_BYTES: [u8; 16] = [
    0x74, 0x65, 0x73, 0x74, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
];
pub(crate) const ZERO_MESSAGE_BYTES_256: [u8; 16] =
    [0x74, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0];

// 765697b2244f246112a0d551aba59013a51e2eb57a229b92be46bf4e1e1c2068
// 85a01b63025ba19b7fd3ddfc033b3e76c9eac6fa700942702e90862383c6c366

// The TLS version converts the 12-byte IV into 16 bytes by padding with 0001.
pub(crate) const IV_BYTES: [u8; 16] = [
    0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x0, 0x0, 0x0,
    0x01, // GCM fills it out like this (when the IV is 12 bytes)
];
pub(crate) const IV_BYTES_256: [u8; 16] = [
    0x3, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
    // This matches the other impl passed in 12 bytes.
    // This is how GCM implements it.
    0x0, 0x0, 0x0, 0x1,
];

pub(crate) const IV_BYTES_SHORT: [u8; 12] =
    [0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31];
pub(crate) const IV_BYTES_SHORT_256: [u8; 12] =
    [0x3, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0];

pub(crate) const SIV_AAD: [u8; 16] =
    [0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0];
