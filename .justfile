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

build:
    cargo build -r

check:
    cargo check --all --tests
    cargo fmt --all --check

format:
    cargo fmt --all

fix:
    cargo clippy --all --tests --fix

lint:
    cargo clippy --all --tests -- -D warnings

run:
    cargo run -r

test:
    RUST_MIN_STACK=8388608 cargo test --all -- --nocapture

@versions:
    rustc --version
    cargo fmt -- --version
    cargo clippy -- --version
