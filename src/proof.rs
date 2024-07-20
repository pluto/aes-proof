
use ark_bn254::{Bn254, Fr};
use ark_circom::{CircomBuilder, CircomConfig, circom::R1CSFile};
use ark_std::rand::thread_rng;
use ark_groth16::Groth16;
use std::fs::File;
use ark_crypto_primitives::snark::SNARK;
use ark_ff::PrimeField;

type GrothBn = Groth16<Bn254>;

// Convert bytes to bits (process in big endian order)
fn push_bytes_as_bits<T: PrimeField>(mut builder: CircomBuilder<T>, field: &str, bytes: &[u8]) -> CircomBuilder<T> {
    for byte in bytes {
        for i in 0..8 {
            let bit = (byte >> (7 - i)) & 1;
            builder.push_input(field, bit as u64);
        }
    }

    builder 
}

// load up the circom
// generate a witness
// generate the proof
// check plaintext
// check success bit
pub fn gen_proof_aes_gcm_siv(key: &[u8], iv: &[u8], ct: &[u8], pt: &[u8]) {
    println!("prep config");
    
    // let cfg = CircomConfig::<Fr>::new(
    //     "./build/tiny_js/tiny.wasm",
    //     "./build/tiny.r1cs",
    // ).unwrap();

    // let mut builder = CircomBuilder::new(cfg);
    // builder.push_input("a", 7);
    // builder.push_input("a", 8);
    // builder.push_input("a", 9);
    // builder.push_input("b", 8);
    // builder.push_input("c", (7*8)*(8+8)+9);

    let cfg = CircomConfig::<Fr>::new(
        "./build/gcm_siv_dec_2_keys_test_js/gcm_siv_dec_2_keys_test.wasm",
        "./build/gcm_siv_dec_2_keys_test.r1cs",
    ).unwrap();

    println!("prep builder");
    let mut builder = CircomBuilder::new(cfg);

    // signal input K1[256];
    // signal input N[128];
    // signal input AAD[n_bits_aad];
    // signal input CT[(msg_len+16)*8];
    
    // No AAD, but the circuit is sensitive to it. Needs 128 bits.
    let aad = [
        0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0
    ];

    builder = push_bytes_as_bits(builder, "K1", key);
    builder = push_bytes_as_bits(builder, "N", iv);
    builder = push_bytes_as_bits(builder, "AAD", &aad);
    builder = push_bytes_as_bits(builder, "CT", ct);

    let reader = File::open("./build/gcm_siv_dec_2_keys_test.r1cs").unwrap();
    let r1cs = R1CSFile::<Fr>::new(reader).unwrap();
    println!("header.n_wires={:?}", r1cs.header.n_wires);
    println!("header.n_pub_out={:?}", r1cs.header.n_pub_out);
    println!("header.n_pub_in={:?}", r1cs.header.n_pub_in);
    println!("header.n_prv_in={:?}", r1cs.header.n_prv_in);
    println!("header.n_labels={:?}", r1cs.header.n_labels);
    println!("header.n_constraints={:?}", r1cs.header.n_constraints);
    println!("inputs={:?}", builder.inputs);

    // create an empty instance for setting it up
    println!("setup builder");
    let circom = builder.setup();
    println!("circuit facts: inputs={}", circom.r1cs.num_inputs);

    println!("load params");
    let mut rng = thread_rng();

    // HANGING? Why.
    println!("gen params");
    // use std::io::BufReader;
    // ./build/tiny.zkey
    // let mut file = File::open("./build/gcm_siv_dec_2_keys_test_0001.zkey").unwrap();
    // let mut reader = BufReader::new(file);
    // println!("file open, parsing");
    // let (params, _matrices) = ark_circom::read_zkey(&mut reader).unwrap();
    
    let params = GrothBn::generate_random_parameters_with_reduction(circom, &mut rng).unwrap();

    println!("build builder");
    let circom = builder.build().unwrap();
    println!("get pub input");
    let inputs = circom.get_public_inputs().unwrap();
    println!("len={:?}", inputs.len());

    // convert bits to bytes
    // let output_bytes = Vec::new();
    fn bits_to_u8(bits: &[u8]) -> u8 {
        bits.iter().rev().enumerate().fold(0, |acc, (i, &bit)| {
            acc | ((bit & 1) << i)
        })
    }
    let mut output_bytes = Vec::new();
    for i in inputs.chunks(8) {
        let mut bits = Vec::new();
        for j in i {
            let bit = if *j == Fr::from(1) {
                1u8
            } else if *j == Fr::from(0) {
                0u8
            } else {
                panic!("results should be bits");
            };
            bits.push(bit);
        }
        let out_byte = bits_to_u8(&bits);
        output_bytes.push(out_byte);
    }

    use ark_relations::r1cs::{ConstraintSystem, ConstraintSynthesizer};
    let cs = ConstraintSystem::<Fr>::new_ref();
    circom.clone().generate_constraints(cs.clone()).unwrap();
    assert!(cs.is_satisfied().unwrap());

    let proof = GrothBn::prove(&params, circom, &mut rng).unwrap();
    println!("proof_a={:?}, proof_b={:?}, proof_c={:?}", proof.a, proof.b, proof.c);

    println!("process vk");
    let pvk = GrothBn::process_vk(&params.vk).unwrap();
    println!("verify");
    let verified = GrothBn::verify_with_processed_vk(&pvk, &inputs, &proof).unwrap();
    println!("verified={:?}", verified);
    assert!(verified);

    // Duplicate check, but ensure the plaintext is correct.
    let pt_bytes = &output_bytes[..pt.len()];
    println!("Output bytes matches plaintext pt={:?}", pt_bytes);
    assert!(pt_bytes.iter().zip(pt.iter()).all(|(&a, &b)| a == b));

    // Check the success bit (mac matches)
    let success_bit = output_bytes[output_bytes.len()-1];
    println!("Success bit={:?}", success_bit);
    assert!(success_bit == 1);
    

}
