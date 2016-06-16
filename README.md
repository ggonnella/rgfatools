The Graphical Fragment Assembly (GFA) is a proposed format which allow
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

This gem is depends on the "gfa" gem.
