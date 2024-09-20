template BytesToBits(n) {
    signal input in[n];
    signal output out[n*8];
    component num2bits[n];
    for (var i = 0; i < n; i++) {
        // ... existing code ...
        for (var j = 0; j < 8; j++) {
            // Reverse the bit order within each byte
            out[i*8 + (7 - j)] <== num2bits[i].out[j];
        }
    }
}