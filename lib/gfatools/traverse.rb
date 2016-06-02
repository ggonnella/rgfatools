#
# Methods for the GFA class, which involve a traversal of the graph following
# links
#
module GFATools::Traverse

  require "set"

  def remove_p_bubbles
    visited = Set.new
    segment_names.each do |sn|
      next if visited.include?(sn)
      if connectivity(sn) == [1,1]
        s1 = neighbours([sn, :B])[0]
        s2 = neighbours([sn, :E])[0]
        n1 = neighbours(s1).sort
        n2 = neighbours(s2).sort
        n1.each {|se| visited << se[0]}
        if n1 == n2.map{|se| other_segment_end(se)}
          remove_proven_p_bubble(s1, s2, n1)
        end
      end
    end
  end

  def remove_p_bubble(segment_end1, segment_end2)
    n1 = neighbours(segment_end1).sort
    n2 = neighbours(segment_end2).sort
    raise if n1 != n2.map{|se| other_segment_end(se)}
    raise if n1.any? {|se| connectivity(se[0]) != [1,1]}
    remove_proven_p_bubble(segment_end1, segment_end2, n1)
  end

  private

  def remove_proven_p_bubble(segment_end1, segment_end2, alternatives)
    coverages = alternatives.map{|s|segment!(s[0]).coverage}
    alternatives.delete_at(coverages.index(coverages.max))
    alternatives.each {|s| delete_segment(s[0])}
  end

end
