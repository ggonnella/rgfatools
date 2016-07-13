#
# Methods which edit the graph components without traversal
#
module RGFATools::Edit

  # Allowed values for the links_distribution_policy option
  LINKS_DISTRIBUTION_POLICY = [:off, :auto, :equal, :E, :B]

  # @!method multiply_without_rgfatools(segment, factor, copy_names: :lowcase, conserve_components: true)
  # Original multiply method of RGFA.
  # @return [RGFA] self
  # See the RGFA API documentation for detail.

  # @overload multiply(segment, factor, copy_names: :lowcase, links_distribution_policy: :auto, conserve_components: true, origin_tag: :or)
  # Create multiple copies of a segment.
  #
  # Complements the multiply method of gfatools with additional functionality.
  # To call the original method use {#multiply_without_rgfatools}.
  #
  # @!macro [new] copynames_text
  #
  #   <b>Automatic computation of the copy names:</b>
  #
  #   - First, itis checked if the name of the original segment ends with a
  #     relevant
  #     string, i.e. a lower case letter (for +:lowcase+), an upper case letter
  #     (for +:upcase+), a digit (for +:number+), or the string +"_copy"+
  #     plus one or more optional digits (for +:copy+).
  #   - If so, it is assumed, it was already a copy, and it is not
  #     altered.
  #   - If not, then +a+ (for +:lowcase+), +A+ (for +:upcase+), +1+ (for
  #     +:number+), +_copy+ (for +:copy+) is appended to the string.
  #   - Then, in all
  #     cases, next (*) is called on the string, until a valid, non-existant
  #     name is found for each of the segment copies
  #   - (*) = except for +:copy+, where
  #     for the first copy no digit is present, but for the following is,
  #     i.e. the segment names will be +:copy+, +:copy2+, +:copy3+, etc.
  # - Can be overridden, by providing an array of copy names.
  #
  # @!macro [new] ldp_text
  #
  #   <b>Links distribution policy</b>
  #
  #   Depending on the value of the option +links_ditribution_policy+, an end
  #   is eventually selected for distribution of the links.
  #
  #   - +:off+: no distribution performed
  #   - +:E+: links of the E end are distributed
  #   - +:B+: links of the B end are distributed
  #   - +:equal+: select an end for which the number of links is equal to
  #     +factor+, if any; if both, then the E end is selected
  #   - +:auto+: automatically select E or B, trying to maximize the number of
  #     links which can be deleted
  #
  # @param [Integer] factor multiplication factor; if 0, delete the segment;
  #   if 1; do nothing; if > 1; number of copies to create
  # @!macro [new] segment_param
  #   @param segment [String, RGFA::Line::Segment] segment name or instance
  # @param [:lowcase, :upcase, :number, :copy, Array<String>] copy_names
  #   <i>(Defaults to: +:lowcase+)</i>
  #   Array of names for the copies of the segment,
  #   or a symbol, which defines a system to compute the names from the name of
  #   the original segment. See "Automatic computation of the copy names".
  # @!macro [new] conserve_components
  #   @param [Boolean] conserve_components <i>(Defaults to: +true+)</i>
  #     If factor == 0 (i.e. deletion), delete segment only if
  #     #cut_segment?(segment) is +false+ (see RGFA API).
  # @!macro [new] ldp_param
  #   @param links_distribution_policy
  #     [RGFATools::Edit::LINKS_DISTRIBUTION_POLICY]
  #     <i>(Defaults to: +:auto+)</i>
  #     Determines if and for which end of the segment, links are distributed
  #     among the copies. See "Links distribution policy".
  # @!macro [new] origin_tag
  #   @param origin_tag [Symbol] <i>(Defaults to: +:or+)</i>
  #     Name of the custom tag to use for storing origin information.
  #
  # @return [RGFA] self
  def multiply_with_rgfatools(segment, factor,
                       copy_names: :lowcase,
                       links_distribution_policy: :auto,
                       conserve_components: true,
                       origin_tag: :or)
    s, sn = segment_and_segment_name(segment)
    s.set(origin_tag, sn) if !s.get(origin_tag)
    copy_names = compute_copy_names(copy_names, sn, factor)
    multiply_without_rgfatools(sn, factor,
                               copy_names: copy_names,
                               conserve_components: conserve_components)
    distribute_links(links_distribution_policy, sn, copy_names, factor)
    return self
  end

  # Sets the count tag to use as default by coverage computations
  # <i>(defaults to: +:RC+)</i>.
  #
  # @return [RGFA] self
  # @param tag [Symbol] the tag to use
  def set_default_count_tag(tag)
    @default[:count_tag] = tag
    return self
  end

  # Sets the unit length (k-mer size, average read lenght or average fragment
  # length) to use for coverage computation
  # <i>(defaults to: 1)</i>.
  #
  # @param unit_length [Integer] the unit length to use
  # @return [RGFA] self
  def set_count_unit_length(unit_length)
    @default[:unit_length] = unit_length
    return self
  end

  # Delete segments which have a coverage under a specified value.
  #
  # @param mincov [Integer] the minimum coverage
  # @!macro [new] count_tag
  #   @param count_tag [Symbol] <i>(defaults to: +:RC+ or the value set by
  #     {#set_default_count_tag})</i> the count tag to use for coverage
  #     computation
  # @!macro [new] unit_length
  #   @param unit_length [Integer] <i>(defaults to: 1 or the value set by
  #     {#set_count_unit_length})</i> the unit length to use for coverage
  #     computation
  #
  # @return [RGFA] self
  def delete_low_coverage_segments(mincov,
                                   count_tag: @default[:count_tag],
                                   unit_length: @default[:unit_length])
    segments.map do |s|
      cov = s.coverage(count_tag: count_tag,
                       unit_length: unit_length)
      cov < mincov ? s.name : nil
    end.compact.each do |sn|
      delete_segment(sn)
    end
    self
  end

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

  # @param mincov [Integer] <i>(defaults to: 1/4 of +single_copy_coverage+)</i>
  #   the minimum coverage, cn for segments under this value is set to 0
  # @param single_copy_coverage [Integer]
  #   the coverage that shall be considered to be single copy
  # @param cn_tag [Symbol] <i>(defaults to: +:cn+)</i>
  #   the tag to use for storing the copy number
  # @!macro count_tag
  # @!macro unit_length
  # @return [RGFA] self
  def compute_copy_numbers(single_copy_coverage,
                           mincov: single_copy_coverage * 0.25,
                           count_tag: @default[:count_tag],
                           cn_tag: :cn,
                           unit_length: @default[:unit_length])
    segments.each do |s|
      cov = s.coverage!(count_tag: count_tag, unit_length: unit_length).to_f
      if cov < mincov
        cn = 0
      elsif cov < single_copy_coverage
        cn = 1
      else
        cn = (cov / single_copy_coverage).round
      end
      s.set(cn_tag, cn)
    end
    self
  end

  # Applies the computed copy number to a segment
  # @!macro [new] apply_copy_number
  #   @!macro ldp_text
  #   @!macro ldp_param
  #   @!macro count_tag
  #   @!macro origin_tag
  #   @!macro conserve_components
  #   @return [RGFA] self
  #   @!macro copynames_text
  #   @param [:lowcase, :upcase, :number, :copy] copy_names_suffix
  #     <i>(Defaults to: +:lowcase+)</i>
  #     Symbol representing a system to compute the names from the name of
  #     the original segment. See "Automatic computation of the copy names".
  # @!macro segment_param
  def apply_copy_number(segment, count_tag: :cn,
                        links_distribution_policy: :auto,
                        copy_names_suffix: :lowcase, origin_tag: :or,
                        conserve_components: true)
    s, sn = segment_and_segment_name(segment)
    factor = s.get!(count_tag)
    multiply(sn, factor,
             links_distribution_policy: links_distribution_policy,
             copy_names: copy_names_suffix,
             conserve_components: conserve_components,
             origin_tag: origin_tag)
    self
  end

  # Applies the computed copy number to all segments
  # @!macro apply_copy_number
  def apply_copy_numbers(count_tag: :cn, links_distribution_policy: :auto,
                         copy_names_suffix: :lowcase, origin_tag: :or,
                         conserve_components: true)
    segments.sort_by{|s|s.get!(count_tag)}.each do |s|
      multiply(s.name, s.get(count_tag),
               links_distribution_policy: links_distribution_policy,
               copy_names: copy_names_suffix,
               conserve_components: conserve_components,
               origin_tag: origin_tag)
    end
    self
  end

  # Selects a random orientation for all invertible segments
  # @return [RGFA] self
  def randomly_orient_invertibles
    segment_names.each do |sn|
      if segment_same_links_both_ends?(sn)
        randomly_orient_proven_invertible_segment(sn)
      end
    end
    self
  end

  # Selects a random orientation for an invertible segment
  # @return [RGFA] self
  # @!macro segment_param
  def randomly_orient_invertible(segment)
    segment_name = segment.kind_of?(RGFA::Line) ? segment.name : segment
    if !segment_same_links_both_ends?(segment_name)
      raise "Only segments with links to the same or equivalent segments "+
              "at both ends can be randomly oriented"
    end
    randomly_orient_proven_invertible_segment(segment_name)
    self
  end

  # Remove superfluous links in the presence of mandatory links
  # for a single segment
  # @return [RGFA] self
  # @!macro segment_param
  # @!macro [new] conserve_components_links
  #   @param [Boolean] conserve_components <i>(Defaults to: +true+)</i>
  #     delete links only if #cut_link?(link) is +false+ (see RGFA API).
  def enforce_segment_mandatory_links(segment, conserve_components: true)
    s, sn = segment_and_segment_name(segment)
    se = {}
    l = {}
    [:B, :E].each do |et|
      se[et] = [sn, et]
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

  # Remove superfluous links in the presence of mandatory links
  # in the entire graph
  # @!macro conserve_components_links
  # @return [RGFA] self
  def enforce_all_mandatory_links(conserve_components: true)
    segment_names.each {|sn| enforce_segment_mandatory_links(sn,
                               conserve_components: conserve_components)}
    self
  end

  # Remove links of segment to itself
  # @!macro segment_param
  # @return [RGFA] self
  def remove_self_link(segment)
    segment_name = segment.kind_of?(RGFA::Line) ? segment.name : segment
    unconnect_segments(segment_name, segment_name)
    self
  end

  # Remove all links of segments to themselves
  # @return [RGFA] self
  def remove_self_links
    segment_names.each {|sn| remove_self_link(sn)}
    self
  end

  private

  Redefined = [:multiply]

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
    [:or].map do |field|
      s.send(field)
    end.join("\t")
  end

  def segments_equivalent?(segment_names)
    raise if segment_names.size < 2
    segments = segment_names.map{|sn|segment!(sn)}
    [:or].each do |field|
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
    n = segment.name.to_s.split("_")
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
    accepted = RGFATools::Edit::LINKS_DISTRIBUTION_POLICY
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
        delete_link(l) unless to_save.include?(l_sig)
      end
    end
  end

  def segment_and_segment_name(segment_or_segment_name)
    if segment_or_segment_name.kind_of?(RGFA::Line)
      s = segment_or_segment_name
      sn = segment_or_segment_name.name
    else
      sn = segment_or_segment_name.to_sym
      s = segment(sn)
    end
    return s, sn
  end

end
