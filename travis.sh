#! /bin/sh
# setup an OCaml environment

sudo add-apt-repository ppa:avsm/ppa
sudo apt-get update
sudo apt-get install -y ocaml ocaml-native-compilers opam

ocamlc -version
opam -version


