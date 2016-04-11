#! /bin/sh

# setup a generic OCaml environment
echo "yes" | sudo add-apt-repository ppa:avsm/ppa
sudo apt-get update -qq
sudo apt-get install -qq ocaml ocaml-native-compilers opam

eval $(opam config env)
opam init
opam install ocamlfind

# set up OCaml for our Mirage kernel
. setup.sh

# build it
make
