#
# Methods for the GFA class, which involve a traversal of the graph following
# links
#
module GFATools::Traverse

  require "set"

  def self.included(mod)
    extended_methods = [:add_segment_to_merged]
    GFATools.redefine_methods(extended_methods, mod)
  end

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

  def reverse_segment_name(name, separator)
    name.split(separator).map do |part|
      openp = part[0] == "("
      part = part[1..-1] if openp
      closep = part[-1] == ")"
      part = part[0..-2] if closep
      part = (part[-1] == "^") ? part[0..-2] : part+"^"
      part += ")" if openp
      part = "(#{part}" if closep
      part
    end.reverse.join(separator)
  end

  def reverse_pos_array(pos_array, lastpos)
    return nil if pos_array.nil? or lastpos.nil?
    pos_array.map {|pos| lastpos - pos + 1}.reverse
  end

  def add_segment_to_merged_with_gfatools(merged, segment, reversed, cut, init)
    s = (reversed ? segment.sequence.rc[cut..-1] : segment.sequence[cut..-1])
    n = (reversed ? reverse_segment_name(segment.name, "_") : segment.name)
    rn = (reversed ? reverse_pos_array(segment.rn, segment.LN) : segment.rn)
    mp = (reversed ? reverse_pos_array(segment.mp, segment.LN) : segment.mp)
    mp = [1, segment.LN] if mp.nil? and segment.LN
    if segment.or.nil?
      o = n
    else
      o = (reversed ? reverse_segment_name(segment.or, ",") : segment.or)
    end
    if init
      merged.sequence = s
      merged.name = n
      merged.LN = segment.LN
      merged.rn = rn
      merged.or = o
      merged.mp = mp
    else
      (segment.sequence == "*") ? (merged.sequence = "*")
                                : (merged.sequence += s)
      merged.name += "_#{n}"
      if merged.LN
        if rn
          rn = rn.map {|pos| pos - cut + merged.LN}
          merged.rn = merged.rn.nil? ? rn : merged.rn + rn
        end
        if mp and merged.mp
          merged.mp += mp.map {|pos| pos - cut + merged.LN}
        end
        segment.LN ? merged.LN += (segment.LN - cut)
                   : merged.LN = nil
      else
        merged.mp = nil
      end
      merged.or = merged.or.nil? ? o : "#{merged.or},#{o}"
    end
  end

end
