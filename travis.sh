#! /bin/sh
# setup an OCaml environment

sudo add-apt-repository ppa:avsm/ppa
sudo apt-get update
sudo apt-get install -y ocaml ocaml-native-compilers opam
sudo apt-get install -y ocamlbuild ocamlfind

ocamlc -version
opam -version


