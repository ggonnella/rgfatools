#
# Methods which edit the graph components without traversal
#
module RGFATools::Artifacts

  # Remove connected components whose sum of lengths of the segments
  # is under a specified value.
  # @param minlen [Integer] the minimum length
  # @return [RGFA] self
  def remove_small_components(minlen)
    rm(connected_components.select {|cc|
      cc.map{|sn|segment!(sn).length}.reduce(:+) < minlen })
    self
  end

  # Remove dead end segments, whose sequence length is under a specified value.
  # @param minlen [Integer] the minimum length
  # @return [RGFA] self
  def remove_dead_ends(minlen)
    rm(segments.select {|s|
      c = connectivity(s); s.length < minlen and
        c[0] == 0 or c[1] == 0 and
        !cut_segment?(s) })
    self
  end

end
