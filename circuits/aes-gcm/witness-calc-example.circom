pragma circom 2.1.9;

include "./aes-gcm-fold.circom";

component main { public [step_in] } = AESGCMFOLD(16, 1024);