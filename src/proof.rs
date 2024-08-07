//! Generate proofs with ark-circom with the circom artifacts and the generated witness

use std::fs::File;

use ark_bn254::{Bn254, Fr};
use ark_circom::{circom::R1CSFile, CircomBuilder, CircomConfig};
use ark_crypto_primitives::snark::SNARK;
use ark_groth16::Groth16;
use ark_std::rand::thread_rng;

type GrothBn = Groth16<Bn254>;
use ark_relations::r1cs::{ConstraintSynthesizer, ConstraintSystem};

use crate::{
    utils::{bits_to_u8, parse_bit_from_field, push_bytes_as_bits},
    witness::Witness,
};

/// load up the circom
/// generate a witness
/// generate the proof
/// check plaintext
/// check success bit
pub fn gen_proof_aes_gcm_siv(witness: &Witness, wtns: &str, r1cs: &str) {
    println!("prep config");

    // read from disk
    let cfg = CircomConfig::<Bn254>::new(wtns, r1cs).unwrap();

    println!("prep builder");
    let mut circom_builder = CircomBuilder::new(cfg);

    // TODO(TK 2024-08-06): replace with const
    // No AAD, but the circuit is sensitive to it. Needs 128 bits.
    // aes ctr has no aad
    let aad = [0; 16];

    // TODO(TK 2024-08-06):
    // code smell: can't tell what this is doing, even by looking at source
    //
    // abstract deeper to initialize witness builder
    // to avoid manipulating circom builder in place
    circom_builder = push_bytes_as_bits(circom_builder, "K1", &witness.key);
    circom_builder = push_bytes_as_bits(circom_builder, "N", &witness.iv);
    circom_builder = push_bytes_as_bits(circom_builder, "AAD", &aad);
    circom_builder = push_bytes_as_bits(circom_builder, "CT", &witness.ct);

    // read r1cs
    let r1cs = R1CSFile::<Bn254>::new(File::open(r1cs).unwrap()).unwrap();

    println!("header.n_wires={:?}", r1cs.header.n_wires);
    println!("header.n_pub_out={:?}", r1cs.header.n_pub_out);
    println!("header.n_pub_in={:?}", r1cs.header.n_pub_in);
    println!("header.n_prv_in={:?}", r1cs.header.n_prv_in);
    println!("header.n_labels={:?}", r1cs.header.n_labels);
    println!("header.n_constraints={:?}", r1cs.header.n_constraints);
    println!("inputs={:?}", circom_builder.inputs);

    // create an empty instance for setting it up
    println!("setup builder");
    let circom = circom_builder.setup();
    println!("circuit facts: inputs={}", circom.r1cs.num_inputs);

    let mut rng = thread_rng();

    // Generates a random common reference string for
    // a circuit using the provided R1CS-to-QAP reduction.
    println!("gen params");
    let params = GrothBn::generate_random_parameters_with_reduction(circom, &mut rng).unwrap();

    // Create the circuit populated with the witness corresponding to the previously
    // provided inputs
    println!("build builder");
    let circom = circom_builder.build().unwrap();

    println!("get pub input");
    let inputs = circom.get_public_inputs().unwrap();
    println!("len={:?}", inputs.len());

    let output_bytes = inputs
        .chunks(8)
        .map(|i| {
            let bits: Vec<u8> = i.iter().map(parse_bit_from_field).collect();
            bits_to_u8(&bits)
        })
        .collect::<Vec<u8>>();

    // generate and test constraints
    let cs = ConstraintSystem::<Fr>::new_ref();
    circom.clone().generate_constraints(cs.clone()).unwrap();
    assert!(cs.is_satisfied().unwrap());

    let proof = GrothBn::prove(&params, circom, &mut rng).unwrap();
    println!("proof_a={:?}, proof_b={:?}, proof_c={:?}", proof.a, proof.b, proof.c);

    println!("process vk");
    let pvk = GrothBn::process_vk(&params.vk).unwrap();

    println!("verify");
    let verified = GrothBn::verify_with_processed_vk(&pvk, &inputs, &proof).unwrap();
    assert!(verified);

    // Duplicate check, but ensure the plaintext is correct.
    let pt_bytes = &output_bytes[..witness.pt.len()];
    println!("Output bytes matches plaintext pt={:?}", pt_bytes);
    assert!(pt_bytes.iter().zip(witness.pt.iter()).all(|(&a, &b)| a == b));

    // Check the success bit (auth_tag matches)
    let success_bit = output_bytes.last().unwrap();
    println!("Success bit={:?}", success_bit);
    assert!(success_bit == &1);
}
