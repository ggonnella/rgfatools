Gem::Specification.new do |s|
  s.name = 'gfatools'
  s.version = '0.9'
  s.date = '2016-06-02'
  s.summary = 'Traverse, edit and simplify GFA-format graphs in Ruby'
  s.description = <<-EOF
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
  EOF
  s.author = 'Giorgio Gonnella'
  s.email = 'gonnella@zbh.uni-hamburg.de'
  s.files = [
              'lib/gfatools.rb',
              'lib/gfatools/edit.rb',
              'lib/gfatools/traverse.rb',
              'bin/gfatools/gfadiff.rb',
              'bin/gfatools/simplify.rb',
              'bin/gfatools/simulate_debrujin.rb',
            ]
  s.homepage = 'http://github.com/ggonnella/ruby-gfa'
  s.license = 'CC-BY-SA'
  s.required_ruby_version = '>= 2.0'
end
