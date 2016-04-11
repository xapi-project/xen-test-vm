#! /bin/sh
# setup an OCaml environment

sudo apt-get install -y ocaml-native-compilers
sudo apt-get install -y ocaml-findlib
sudo apt-get install -y opam

ocamlc -version
opam -version


