# A configuration file for `just`, a command runner and successor to `make`
# https://github.com/casey/just/tree/master
#
# examples:
# https://github.com/casey/just/blob/master/examples/pre-commit.just
# https://github.com/casey/just/blob/master/examples/kitchen-sink.just

# ignore comments in the command area
set ignore-comments := true 

# load .env vars
# set dotenv-load := true 

# set custom env vars
export RUST_LOG := "info"
# export RUST_BACKTRACE := "1"


@just:
    just --list

install:
    npm install

circom-test:
    npx mocha

# commented out when test flow added, remove soon 2024-08-10 
# circom-build-ghash:
#    circom --wasm --sym --r1cs --output build circuits/aes-gcm/ghash.circom

@versions:
    rustc --version
    cargo fmt -- --version
    cargo clippy -- --version
