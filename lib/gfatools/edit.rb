module GFATools::Edit

  Redefined = [:multiply, :duplicate]

  def multiply_with_gfatools(segment_name, factor,
                       copy_names: :lowcase,
                       links_distribution_policy: :auto,
                       conserve_components: true,
                       origin_tag: :or)
    s = segment(segment_name)
    s.send(:"#{origin_tag}=", s.name) if !s.send(origin_tag)
    copy_names = compute_copy_names(copy_names, segment_name, factor)
    multiply_without_gfatools(segment_name, factor,
                                      copy_names: copy_names,
                                      conserve_components: conserve_components)
    distribute_links(links_distribution_policy, segment_name, copy_names,
                     factor)
    return self
  end

  def duplicate_with_gfatools(segment_name, copy_name: :lowcase,
                       links_distribution_policy: :auto,
                       conserve_components: true,
                       origin_tag: :or)
    multiply_with_gfatools(segment_name, 2,
                     copy_names:
                       copy_name.kind_of?(String) ? [copy_name] : copy_name,
                     links_distribution_policy: links_distribution_policy,
                     conserve_components: conserve_components,
                     origin_tag: origin_tag)
  end


  def delete_low_coverage_segments(mincov, count_tag: :RC)
    segments.map do |s|
      cov = s.coverage(count_tag: count_tag)
      cov < mincov ? s.name : nil
    end.compact.each do |sn|
      delete_segment(sn)
    end
    self
  end

  def remove_small_components(minlen)
    rm(connected_components.select {|cc|
      cc.map{|sn|segment!(sn).length}.reduce(:+) < minlen })
    self
  end

  def remove_dead_ends(minlen)
    rm(segments.select {|s|
      c = connectivity(s); s.length < minlen and
        c[0] == 0 or c[1] == 0 and
        !cut_segment?(s) })
    self
  end

  def compute_copy_numbers(single_copy_coverage,
                           mincov: single_copy_coverage * 0.25,
                           count_tag: :RC, tag: :cn)
    segments.each do |s|
      cov = s.coverage!(count_tag: count_tag).to_f
      if cov < mincov
        cn = 0
      elsif cov < single_copy_coverage
        cn = 1
      else
        cn = (cov / single_copy_coverage).round
      end
      s.send(:"#{tag}=", cn)
    end
    self
  end

  def apply_copy_number(segment_name, tag: :cn,
                        links_distribution_policy: :auto,
                        copy_names_suffix: :lowcase, origin_tag: :or,
                        conserve_components: true)
    s = segment!(segment_name)
    factor = s.send(:"#{tag}!")
    multiply(segment_name, factor,
             links_distribution_policy: links_distribution_policy,
             copy_names: copy_names_suffix,
             conserve_components: conserve_components,
             origin_tag: origin_tag)
    self
  end

  def apply_copy_numbers(tag: :cn, links_distribution_policy: :auto,
                         copy_names_suffix: :lowcase, origin_tag: :or,
                         conserve_components: true)
    segments.sort_by{|s|s.send(:"#{tag}!")}.each do |s|
      multiply(s.name, s.send(tag),
               links_distribution_policy: links_distribution_policy,
               copy_names: copy_names_suffix,
               conserve_components: conserve_components,
               origin_tag: origin_tag)
    end
    self
  end

  def randomly_orient_invertibles
    segment_names.each do |sn|
      if segment_same_links_both_ends?(sn)
        randomly_orient_proven_invertible_segment(sn)
      end
    end
    self
  end

  def randomly_orient_invertible(segment_name)
    if !segment_same_links_both_ends?(sn)
      raise "Only segments with links to the same or equivalent segments "+
              "at both ends can be randomly oriented"
    end
    randomly_orient_proven_invertible_segment(segment_name)
    self
  end

  def enforce_segment_mandatory_links(segment_name, conserve_components: true)
    s = segment!(segment_name)
    se = {}
    l = {}
    [:B, :E].each do |et|
      se[et] = [s.name, et]
      l[et] = links_of(se[et])
    end
    cs = connectivity_symbols(l[:B].size, l[:E].size)
    if cs == [1, 1]
      oe = {}
      [:B, :E].each {|et| oe[et] = l[et][0].other_end(se[et])}
      return if oe[:B] == oe[:E]
      [:B, :E].each {|et| delete_other_links(oe[et], se[et],
                                    conserve_components: conserve_components)}
    else
      i = cs.index(1)
      return if i.nil?
      et = [:B, :E][i]
      oe = l[et][0].other_end(se[et])
      delete_other_links(oe, se[et], conserve_components: conserve_components)
    end
    self
  end

  def enforce_all_mandatory_links(conserve_components: true)
    segment_names.each {|sn| enforce_segment_mandatory_links(sn,
                               conserve_components: conserve_components)}
    self
  end

  def remove_self_link(segment_name)
    unconnect_segments(segment_name, segment_name)
    self
  end

  def remove_self_links
    segment_names.each {|sn| remove_self_link(sn)}
    self
  end

  private

  def randomly_orient_proven_invertible_segment(segment_name)
    parts = partitioned_links_of([segment_name, :E])
    if parts.size == 2
      tokeep1_other_end = parts[0][0].other_end([segment_name, :E])
      tokeep2_other_end = parts[1][0].other_end([segment_name, :E])
    elsif parts.size == 1 and parts[0].size == 2
      tokeep1_other_end = parts[0][0].other_end([segment_name, :E])
      tokeep2_other_end = parts[0][1].other_end([segment_name, :E])
    else
      return
    end
    return if links_of(tokeep1_other_end).size < 2
    return if links_of(tokeep2_other_end).size < 2
    delete_other_links([segment_name, :E], tokeep1_other_end)
    delete_other_links([segment_name, :B], tokeep2_other_end)
    annotate_random_orientation(segment_name)
  end

  def link_targets_for_cmp(segment_end)
    links_of(segment_end).map {|l| l.other_end(segment_end).join}
  end

  def segment_same_links_both_ends?(segment_name)
    e_links = link_targets_for_cmp([segment_name, :E])
    b_links = link_targets_for_cmp([segment_name, :B])
    return e_links == b_links
  end

  def segments_same_links?(segment_names)
    raise if segment_names.size < 2
    e_links_first = link_targets_for_cmp([segment_names.first, :E])
    b_links_first = link_targets_for_cmp([segment_names.first, :B])
    return segment_names[1..-1].all? do |sn|
      (link_targets_for_cmp([sn, :E]) == e_links_first) and
      (link_targets_for_cmp([sn, :B]) == b_links_first)
    end
  end

  def segment_signature(segment_end)
    s = segment!(segment_end[0])
    link_targets_for_cmp(segment_end).join(",")+"\t"+
    link_targets_for_cmp(other_segment_end(segment_end)).join(",")+"\t"+
    [:or, :coverage].map do |field|
      s.send(field)
    end.join("\t")
  end

  def segments_equivalent?(segment_names)
    raise if segment_names.size < 2
    segments = segment_names.map{|sn|segment!(sn)}
    [:or, :coverage].each do |field|
      if segments.any?{|s|s.send(field) != segments.first.send(field)}
        return false
      end
    end
    return segment_same_links?(segment_names)
  end

  def partitioned_links_of(segment_end)
    links_of(segment_end).group_by do |l|
      other_end = l.other_end(segment_end)
      sig = segment_signature(other_end)
      sig
    end.map {|sig, par| par}
  end

  def annotate_random_orientation(segment_name)
    segment = segment!(segment_name)
    n = segment.name.split("_")
    pairs = 0
    pos = [1, segment.LN]
    if segment.or
      o = segment.or.split(",")
      if o.size > 2
        while o.last == o.first + "^" or o.last + "^" == o.first
          pairs += 1
          o.pop
          o.shift
        end
      end
      if segment.mp
        pos = [segment.mp[pairs*2], segment.mp[-1-pairs*2]]
      end
    end
    rn = segment.rn
    rn ||= []
    rn += pos
    segment.rn = rn
    n[pairs] = "(" + n[pairs]
    n[-1-pairs] = n[-1-pairs] + ")"
    rename(segment.name, n.join("_"))
  end

  def select_distribute_end(links_distribution_policy, segment_name, factor)
    accepted = [:off, :auto, :equal, :E, :B]
    if !accepted.include?(links_distribution_policy)
      raise "Unknown links_distribution_policy, accepted values are: "+
        accepted.inspect
    end
    return nil if links_distribution_policy == :off
    if [:B, :E].include?(links_distribution_policy)
      return links_distribution_policy
    end
    esize = links_of([segment_name, :E]).size
    bsize = links_of([segment_name, :B]).size
    if esize == factor
      return :E
    elsif bsize == factor
      return :B
    elsif links_distribution_policy == :equal
      return nil
    elsif esize < 2
      return (bsize < 2) ? nil : :B
    elsif bsize < 2
      return :E
    elsif esize < factor
      return ((bsize <= esize) ? :E :
        ((bsize < factor) ? :B : :E))
    elsif bsize < factor
      return :B
    else
      return ((bsize <= esize) ? :B : :E)
    end
  end

  def distribute_links(links_distribution_policy, segment_name,
                       copy_names, factor)
    return if factor < 2
    end_type = select_distribute_end(links_distribution_policy,
                                     segment_name, factor)
    return nil if end_type.nil?
    et_links = links_of([segment_name, end_type])
    diff = [et_links.size - factor, 0].max
    links_signatures = et_links.map do |l|
      l.other_end([segment_name, end_type]).join
    end
    ([segment_name]+copy_names).each_with_index do |sn, i|
      links_of([sn, end_type]).each do |l|
        l_sig = l.other_end([sn, end_type]).join
        to_save = links_signatures[i..i+diff].to_a
        delete_link_line(l) unless to_save.include?(l_sig)
      end
    end
  end

end
