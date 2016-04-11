#! /bin/sh
# setup an OCaml environment

echo "yes" | sudo add-apt-repository ppa:avsm/ppa
sudo apt-get update -qq
sudo apt-get install -qq ocaml ocaml-native-compilers opam

eval $(opam config env)
opam init
opam install ocamlfind

ocamlc -version
opam -version


