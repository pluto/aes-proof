use std::fs::File;

use ark_bn254::{Bn254, Fr};
use ark_circom::{circom::R1CSFile, CircomBuilder, CircomConfig};
use ark_crypto_primitives::snark::SNARK;
use ark_groth16::Groth16;
use ark_std::rand::thread_rng;

type GrothBn = Groth16<Bn254>;
use ark_relations::r1cs::{ConstraintSynthesizer, ConstraintSystem};

use crate::{push_bytes_as_bits, Witness};

// load up the circom
// generate a witness
// generate the proof
// check plaintext
// check success bit
// key: &[u8], iv: &[u8], ct: &[u8], pt: &[u8]
pub fn gen_proof_aes_gcm_siv(witness: &Witness, wtns: &str, r1cs: &str) {
    println!("prep config");

    // read from disk
    let cfg = CircomConfig::<Bn254>::new(wtns, r1cs).unwrap();

    println!("prep builder");
    let mut builder = CircomBuilder::new(cfg);

    // No AAD, but the circuit is sensitive to it. Needs 128 bits.
    let aad = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; // aes ctr has no aad

    builder = push_bytes_as_bits(builder, "K1", &witness.key);
    builder = push_bytes_as_bits(builder, "N", &witness.iv);
    builder = push_bytes_as_bits(builder, "AAD", &aad);
    builder = push_bytes_as_bits(builder, "CT", &witness.ct);

    // read from disk again
    let reader = File::open(r1cs).unwrap();
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

    println!("gen params");
    let params = GrothBn::generate_random_parameters_with_reduction(circom, &mut rng).unwrap();

    println!("build builder");
    let circom = builder.build().unwrap();
    println!("get pub input");
    let inputs = circom.get_public_inputs().unwrap();
    println!("len={:?}", inputs.len());

    // convert bits to bytes
    fn bits_to_u8(bits: &[u8]) -> u8 {
        bits.iter().rev().enumerate().fold(0, |acc, (i, &bit)| acc | ((bit & 1) << i))
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
    let pt_bytes = &output_bytes[..witness.pt.len()];
    println!("Output bytes matches plaintext pt={:?}", pt_bytes);
    assert!(pt_bytes.iter().zip(witness.pt.iter()).all(|(&a, &b)| a == b));

    // Check the success bit (auth_tag matches)
    let success_bit = output_bytes[output_bytes.len() - 1];
    println!("Success bit={:?}", success_bit);
    assert!(success_bit == 1);
}
