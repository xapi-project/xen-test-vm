#
#

FROM ocaml/opam:debian-9_ocaml-4.02.3
LABEL distro_style="apt" 
LABEL distro="debian" 
LABEL distro_long="debian-9" 
LABEL arch="x86_64" 
LABEL ocaml_version="4.02.3" 
LABEL opam_version="1.2.2" 
LABEL operatingsystem="linux"

USER opam
ENV HOME /home/opam
WORKDIR /home/opam

RUN opam install -q -y mirage-xen
RUN opam install -q -y mirage-console
RUN opam install -q -y mirage-bootvar-xen
RUN opam install -q -y mirage
RUN opam install -q -y yojson

ENTRYPOINT [ "opam", "config", "exec", "--" ]
CMD [ "bash" ]
