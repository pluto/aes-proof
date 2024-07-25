use ark_bn254::{Bn254, Fr, Fq};
use ark_circom::{circom::R1CSFile, CircomBuilder, CircomConfig};
use ark_crypto_primitives::snark::SNARK;
use ark_ec::pairing::Pairing;
use ark_ff::PrimeField;
use ark_groth16::Groth16;
use ark_std::rand::thread_rng;
use std::fs::File;

type GrothBn = Groth16<Bn254>;

// Convert bytes to bits (process in big endian order)
fn push_bytes_as_bits<T: Pairing>(
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

// load up the circom
// generate a witness
// generate the proof
// check plaintext
// check success bit
pub fn gen_proof_aes_gcm_siv(key: &[u8], iv: &[u8], ct: &[u8], pt: &[u8]) {
    println!("prep config");

    let cfg = CircomConfig::<Bn254>::new(
        "./build/gcm_siv_dec_2_keys_test_js/gcm_siv_dec_2_keys_test.wasm",
        "./build/gcm_siv_dec_2_keys_test.r1cs",
    )
    .unwrap();

    println!("prep builder");
    let mut builder = CircomBuilder::new(cfg);

    // No AAD, but the circuit is sensitive to it. Needs 128 bits.
    let aad = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

    builder = push_bytes_as_bits(builder, "K1", key);
    builder = push_bytes_as_bits(builder, "N", iv);
    builder = push_bytes_as_bits(builder, "AAD", &aad);
    builder = push_bytes_as_bits(builder, "CT", ct);

    let reader = File::open("./build/gcm_siv_dec_2_keys_test.r1cs").unwrap();
    let r1cs = R1CSFile::<Bn254>::new(reader).unwrap();
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
    use std::io::BufReader;
    // ./build/tiny.zkey
    // let mut file = File::open("./build/test_new_0001.zkey").unwrap();
    // let mut reader = BufReader::new(file);
    // println!("file open, parsing");
    // let (params, _matrices) = ark_circom::read_zkey(&mut file).unwrap();

    let params = GrothBn::generate_random_parameters_with_reduction(circom, &mut rng).unwrap();

    // Under the hood this just calls the zkey thing
    // let r = ark_zkey::read_proving_key_and_matrices_from_zkey("./build/test_new_0000.zkey").unwrap();
    // let params = r.0.0;

    // let r = ark_zkey::read_arkzkey("./build/test_0000.arkzkey").unwrap();
    // let params = r.0;

    println!("build builder");
    let circom = builder.build().unwrap();
    println!("get pub input");
    let inputs = circom.get_public_inputs().unwrap();
    println!("len={:?}", inputs.len());

    // convert bits to bytes
    // let output_bytes = Vec::new();
    fn bits_to_u8(bits: &[u8]) -> u8 {
        bits.iter()
            .rev()
            .enumerate()
            .fold(0, |acc, (i, &bit)| acc | ((bit & 1) << i))
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

    use ark_relations::r1cs::{ConstraintSynthesizer, ConstraintSystem};
    let cs = ConstraintSystem::<Fr>::new_ref();
    circom.clone().generate_constraints(cs.clone()).unwrap();
    assert!(cs.is_satisfied().unwrap());

    let proof = GrothBn::prove(&params, circom, &mut rng).unwrap();
    println!(
        "proof_a={:?}, proof_b={:?}, proof_c={:?}",
        proof.a, proof.b, proof.c
    );

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

    // Check the success bit (auth_tag matches)
    let success_bit = output_bytes[output_bytes.len() - 1];
    println!("Success bit={:?}", success_bit);
    assert!(success_bit == 1);
}
