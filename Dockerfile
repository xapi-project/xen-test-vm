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

RUN opam pin add -n -y mirage-xen \
    git://github.com/jonludlam/mirage-platform#reenable-suspend-resume2
RUN opam pin add -n -y mirage-bootvar-xen \
    git://github.com/jonludlam/mirage-bootvar-xen#better-parser
RUN opam pin add -n -y minios-xen \
    git://github.com/jonludlam/mini-os#suspend-resume3

RUN opam install -q -y mirage-xen
RUN opam install -q -y mirage-console
RUN opam install -q -y mirage-bootvar-xen
RUN opam install -q -y mirage
RUN opam install -q -y yojson

ENTRYPOINT [ "opam", "config", "exec", "--" ]
CMD [ "bash" ]
