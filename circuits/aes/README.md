# AES-GCM Implementation in Circom
Circom circuits for aes-gcm-siv, borrowed from [electron-labs/aes-circom](https://github.com/Electron-Labs/aes-circom).

❗❗❗ Note that these circuits have been [shown](https://github.com/Electron-Labs/aes-circom/issues/25) to be underconstrained. ❗❗❗

We intend to work on correctly constraining these circuits.

This is based on the S-table implementation of [AES GCM SIV](https://datatracker.ietf.org/doc/html/rfc8452) encryption scheme.

It is heavily inspired by the C implementation of [AES-GCM-SIV](https://github.com/Shay-Gueron/AES-GCM-SIV)