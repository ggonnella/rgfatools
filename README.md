The Graphical Fragment Assembly (GFA)
described under https://github.com/pmelsted/GFA-spec/blob/master/GFA-spec.md
is a proposed format which allows
to describe the product of sequence assembly and is implemented in the
GFA class defined in the gfa gem. This gem represents an extension of the
GFA class.

Methods in this gem allow, e.g., to randomly orient a segment which has
the same connections on both sides, to compute copy numbers and multiply
or delete segments according to them, to distribute the links of copies
after multipling a segment, or to eliminate edges in the graph which
are incompatible with an hamiltonian path.
Thereby additional conventions are required, with respect to the GFA
specification, which are compatible with it.

Custom optional fields
are defined, such as "cn" for the copy number of a segment,
"or" for the original segment(s) of a duplicated or merged segment,
"mp" for the starting position of original segments in a merged segment,
"rp" for the position of possible inversions due to arbitrary orientation
of some segments by the program.

Furthermore a convention for the naming of the segments is introduced,
which gives a special meaning to the characters "_^()".

This gem is depends on the "rgfa" gem. Please install the rgfa gem
first (https://github.com/ggonnella/rgfa).

The API documentation is available as pdf under
https://github.com/ggonnella/rgfatools/blob/master/pdfdoc/rgfatools-api-1.1.pdf
or in HTML format (http://www.rubydoc.info/github/ggonnella/rgfatools/master/RGFA).

# References

Giorgio Gonnella, Stefan Kurtz, "RGFA: powerful and convenient handling of
assembly graphs" (2016)

The manuscript describing the library has been accepted for presentation at
the German Conference on Bioinformatics 2016. The PeerJ preprint will be linked
here, as soon as available.

