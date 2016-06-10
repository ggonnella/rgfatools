#!/usr/bin/env ruby

require "gfatools"

# crisprs have a structure ARU1RU..RUnRB where |U|~|R| in [24..50]

$debugmode = false
$spacersonly = false

class GFA

  def find_crisprs(minrepeats=3,minlen=24,maxlen=50)
    ls = {}
    segment_names.each do |sn|
      s = segment(sn)
      s.cn = (s.coverage(unit_length: @default[:unit_length],
                        count_tag: @default[:count_tag])/2).round
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
        maxvisits[sn.to_sym] ||= s.cn
        circles[rt] = []
        linear[rt] = []
        links_of([sn, rt]).each do |l|
          loop do 
            mv = maxvisits[sn.to_sym]
            search_circle(other_segment_end([sn,rt]),[sn,rt],l,maxvisits,0,
                          maxlen*2+s.length,[[sn,rt]],circles[rt],linear[rt])
            #p [sn, mv]
            break if maxvisits[sn.to_sym] < 1 or maxvisits[sn.to_sym] == mv
          end
        end
        if false # sn == "1000"
          segment_names.each do |sn1|
            s1 = segment(sn1)
            puts "#{s1.name}\t#{s1.cn}\t"+
              "#{neighbours([s1.name,:B]).map{|nb|segment(nb[0]).cn}.inject(:+)}\t"+
              "#{neighbours([s1.name,:E]).map{|nb|segment(nb[0]).cn}.inject(:+)}\t"+
              "#{links_of([s1.name,:B]).size}\t"+
              "#{links_of([s1.name,:E]).size}\t"+
              "#{s1.KC}\t#{s1.length}\t#{maxvisits[sn1.to_sym]}"
          end
        end
      end
      n_paths = (circles[:E].size+circles[:B].size+
                 linear[:E].size+linear[:B].size)
      if (circles[:E].size - circles[:B].size).abs > 1
        #p [circles[:E].size,circles[:B].size]
        #p "ncircles diff"
        next
      end
      if (linear[:E].size - linear[:B].size).abs > 0
        #p "nlin diff"
        next
      end
      if linear[:E].size != 1
        #p "nlin > 1"
        next
      end
      merged_circles = []
      all_circles = circles[:E]
      #all_circles += circles[:B].map{|c|reverse_segpath(c)}
      #all_circles.uniq!
      all_circles.each {|c|merged_circles << merge_crisprs_path(c,s,:E)}
      before = merge_crisprs_path(linear[:B][0],s,:B)
      after = merge_crisprs_path(linear[:E][0],s,:E)
      next if merged_circles.size < minrepeats
      instances = 1
      possible_instances = 0
      merged_circles.each do |seq|
        if seq.length > s.length + minlen
          possible_instances += 1
        end
        instances += 1
      end
      if $spacersonly
        puts merged_circles.sort.map(&:upcase)
      else
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
            this_asterisk = true
          else
            str = ""
            this_asterisk = false
          end
          puts "    (#{i+1}#{this_asterisk ? "*" : ""})\t"+
            "length = #{seq.length}#{str};\tsequence = #{seq}"
        end
        if asterisk
          puts
          puts "    * = possibly containing inexact repeat instance"
        end
        puts
        puts "After: sequence = #{after[0..49]}..."
      end
    end
  end

  private

  def merge_crisprs_path(segpath,repeat,repeat_end)
    merged = create_merged_segment(segpath, merged_name: :short,
                                 disable_tracking: true)[0]
    sequence = merged.sequence[repeat.
                                 sequence.length..-(1+repeat.sequence.length)]
    sequence = sequence.rc if repeat_end == :B
    return sequence
  end

  def search_circle(goal,from,l,maxvisits,dist,maxdist,path,circles,linear)
    dest_end = l.other_end(from)
    debug = false # goal[0] == "1000"
    if debug
      puts
      puts "Visiting: #{dest_end[0]}"
      puts "- path: #{path.map{|x|x[0]}.inspect}"
      puts "- circles size: #{circles.size}"
      puts "- linear size: #{linear.size}"
      puts
    end
    dest = segment(dest_end[0])
    destsym = dest.name.to_sym
    maxvisits[destsym] ||= dest.cn
    if debug and from[0] == "999"
      puts "Visiting a nb of 999 (mv=#{maxvisits[:"999"]}) #{dest_end[0]} / maxvisits=#{maxvisits[destsym]}"
    end
    se = other_segment_end(dest_end)
    if dest_end == goal
      puts "goal reached" if debug
      new_path = path.dup
      new_path << se
      new_path[0..-2].each {|x| maxvisits[x[0].to_sym] -= 1}
      circles << new_path
      return
    end
    if maxvisits[destsym] == 0
      puts "too many visits" if debug
      return
    end
    if path.any?{|x|x[0]==dest_end[0]}
      puts "path circular before goal" if debug
      return
    end
    new_path = path.dup
    new_path << se
    dist += dest.length - l.overlap[0][0]
    if dist > maxdist
      puts "path linear as too long" if debug
      new_path = path.dup
      new_path << se
      new_path[0..-1].each {|x| maxvisits[x[0].to_sym] -= 1}
      linear << new_path
      return
    end
    ls = links_of(se)
    if ls.size == 0
      puts "path linear as end reached" if debug
      new_path[0..-1].each {|x| maxvisits[x[0].to_sym] -= 1}
      linear << new_path
      return
    end
    ls.each do |next_l|
      next_dest = segment(next_l.other_end(se)[0])
      maxvisits[next_dest.name.to_sym] ||= next_dest.cn
      next if maxvisits[next_dest.name.to_sym] == 0
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
gfa.set_count_unit_length(gfa.headers_data[:ks]-1)
gfa.find_crisprs

