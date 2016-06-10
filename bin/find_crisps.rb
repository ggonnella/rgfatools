#!/usr/bin/env ruby

require "gfa"

# crisps have a structure ARU1RU..RUnRB where |U|~|R| in [24..50]

$debugmode = false

class GFA

  def find_crisps(minrepeats=3,minlen=24,maxlen=50)
    ls = {}
    segment_names.each do |sn|
      s = segment(sn)
      s.cn = s.coverage(unit_length: @default[:unit_length],
                        count_tag: @default[:count_tag])
    end
    if $debugmode
      segment_names.each do |sn|
      s = segment(sn)
        puts "#{s.name}\t#{s.cn}\t"+
          "#{neighbours([s.name,:B]).map{|nb|segment(nb[0]).cn}.inject(:+)}\t"+
          "#{neighbours([s.name,:E]).map{|nb|segment(nb[0]).cn}.inject(:+)}\t"+
          "#{links_of([s.name,:B]).size}\t"+
          "#{links_of([s.name,:E]).size}\t"+
          "#{s.KC}\t#{s.length}"
      end
    end
    segment_names.each do |sn|
      s = segment(sn)
      next if s.length < minlen or s.length > maxlen
      next if s.cn < minrepeats
      circles = {}
      linear = {}
      [:B, :E].each do |rt|
        maxvisits = {}
        circles[rt] = []
        linear[rt] = []
        links_of([sn, rt]).each do |l|
          search_circle(other_segment_end([sn,rt]),[sn,rt],l,maxvisits,0,
                        maxlen*2+s.length,[[sn,rt]],circles[rt],linear[rt])
        end
      end
      n_paths = (circles[:E].size+circles[:B].size+
                 linear[:E].size+linear[:B].size)
      next if (circles[:E].size - circles[:B].size).abs > 0
      next if (linear[:E].size - linear[:B].size).abs > 0
      next if linear[:E].size != 1
      merged_circles = []
      all_circles = circles[:E]
      #all_circles += circles[:B].map{|c|reverse_segpath(c)}
      #all_circles.uniq!
      all_circles.each {|c|merged_circles << merge_crisps_path(c,s,:E)}
      before = merge_crisps_path(linear[:B][0],s,:B)
      after = merge_crisps_path(linear[:E][0],s,:E)
      next if merged_circles.size < minrepeats
      instances = 1
      possible_instances = 0
      merged_circles.each do |seq|
        if seq.length > s.length + minlen
          possible_instances += 1
        else
          instances += 1
        end
      end
      puts "CRISP signature found in segment #{s.name}"
      puts
      puts "  Before: sequence = ...#{before[-50..-1]}"
      puts
      if possible_instances > 0
        instances = "#{instances}..#{instances+possible_instances}"
      end
      puts "  Repeat: instances = #{instances}; "+
           "length = #{s.length};\t"+
           "sequence = #{s.sequence}"
      puts
      puts "  Spacers:"
      asterisk = false
      merged_circles.each_with_index do |seq, i|
        if seq.length > s.length + minlen
          str = "=#{s.length}+2*#{(seq.length.to_f - s.length)/2}"
          asterisk = true
        else
          str = ""
        end
        puts "    (#{i+1})\tlength = #{seq.length}#{str};\tsequence = #{seq}"
      end
      if asterisk
        puts
        puts "    * = possibly containing inexact repeat instance"
      end
      puts
      puts "After: sequence = #{after[0..49]}..."
    end
  end

  private

  def merge_crisps_path(segpath,repeat,repeat_end)
    merged = create_merged_segment(segpath, merged_name: :short,
                                 disable_tracking: true)[0]
    sequence = merged.sequence[repeat.
                                 sequence.length..-(1+repeat.sequence.length)]
    sequence = sequence.rc if repeat_end == :B
    return sequence
  end

  def search_circle(goal,from,l,maxvisits,dist,maxdist,path,circles,linear)
    dest_end = l.other_end(from)
    dest = segment(dest_end[0])
    destsym = dest.name.to_sym
    maxvisits[destsym] ||= dest.cn
    return if maxvisits[destsym] == 0
    new_path = path.dup
    se = other_segment_end(dest_end)
    new_path << se
    maxvisits[destsym] -= 1
    if dest_end == goal
      circles << new_path
      return
    end
    dist += dest.length - l.overlap[0][0]
    if dist > maxdist
      linear << new_path
      return
    end
    ls = links_of(se)
    if ls.size == 0
      linear << new_path
      return
    end
    ls.each do |next_l|
      search_circle(goal,se,next_l,maxvisits,dist,maxdist,new_path,
                   circles,linear)
    end
    return
  end

end

if (ARGV.size == 0)
  STDERR.puts "Usage: #$0 <gfa>"
  exit 1
end
gfa = GFA.from_file(ARGV[0])
gfa.set_default_count_tag(:KC)
gfa.set_count_unit_length(gfa.headers_data[:ks])
gfa.find_crisps

