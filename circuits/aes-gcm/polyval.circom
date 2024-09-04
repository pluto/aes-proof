template POLYVAL(n_msg_bits)
{
    signal input msg[n_msg_bits]; 
    signal input H[128]; 
    // signal input T[2][64]; // TODO
    signal output out[128];

    for (var i = 0; i < 128; i++) {
        out[i] <== 1;
    }

}