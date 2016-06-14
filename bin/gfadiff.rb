#!/usr/bin/env ruby

require "gfa"

rt = []
all_rt = %W[-h -s -l -c -p]
all_rt.each do |rtopt|
  rt << ARGV.delete(rtopt)
end
rt.compact!
rt = all_rt if rt.empty?

out_identical = ARGV.delete("-i")

out_script = ARGV.delete("-script")

if ARGV.size != 2
  STDERR.puts "Compare two GFA files"
  STDERR.puts 
  STDERR.puts "Usage: #$0 [-h] [-s] [-l] [-c] [-p] [-i] [-script] <gfa1> <gfa2>"
  STDERR.puts
  STDERR.puts "If a combination of -h,-s,-l,-c and/or -p is specified, then"
  STDERR.puts "only record of the specified type [h=headers, s=segments, "
  STDERR.puts "l=links, c=containments, p=paths] are compared. "
  STDERR.puts "(default: -h -s -l -c -p)"
  STDERR.puts
  STDERR.puts "Other options:"
  STDERR.puts "  -i: output msg if identical"
  STDERR.puts "  -script: create ruby script to transform gfa1 in gfa2"
  exit 1
end

if out_script
  puts "#!/usr/bin/env ruby"
  puts
  puts "#"
  puts "# This script was automatically generated using gfadiff.rb"
  puts "#"
  puts "# Purpose: edit gfa1 into gfa2"
  puts "#"
  puts "# gfa1: #{ARGV[0]}"
  puts "# gfa2: #{ARGV[1]}"
  puts "#"
  puts
  puts "require \"gfa\""
  puts
  puts "gfa = GFA.from_file(\"#{ARGV[0]}\")"
  puts
end

gfa1 = GFA.new
gfa1.turn_off_validations
gfa1.read_file(ARGV[0], validate: false)
gfa2 = GFA.new
gfa2.turn_off_validations
gfa2.read_file(ARGV[1], validate: false)

if rt.include?("-h")
  h1 = gfa1.headers_data
  h2 = gfa2.headers_data
  if h1 == h2
    if out_identical
      puts "# Header values are identical"
    elsif out_script
      puts "# Headers"
      puts "# ... are identical"
      puts
    end
  else
    if out_script
      puts "# Headers"
      puts
      puts "hd = gfa.headers_data"
    end
    (h1.keys - h2.keys).each do |k|
      v = h1[k].inspect
      if out_script
        puts "hd.delete(#{k.inspect})"
      else
        puts "<\t[headers/exclusive]\t#{k.inspect}\t#{v}"
      end
    end
    (h2.keys - h1.keys).each do |k|
      v = h2[k].inspect
      if out_script
        puts "hd[#{k.inspect}]=#{v}"
      else
        puts ">\t[headers/exclusive]\t#{k.inspect}\t#{v}"
      end
    end
    (h1.keys & h2.keys).each do |k|
      v1 = h1[k]
      v2 = h2[k]
      if v1 != v2
        if out_script
          puts "hd[#{k.inspect}]=#{v2.inspect}"
        else
          puts "<\t[headers/valuediff/#{k}]\t#{v1}"
          puts ">\t[headers/valuediff/#{k}]\t#{v2}"
        end
      end
    end
    if out_script
      puts "gfa.set_headers(hd)"
      puts
    end
  end
end

def diff_segments_or_paths(gfa1,gfa2,rt,out_script,out_identical)
  rts = rt + "s"
  rtsU = rts[0].upcase + rts[1..-1]
  s1names = gfa1.send("#{rt}_names").sort
  s2names = gfa2.send("#{rt}_names").sort
  difffound = false
  if out_script
    puts "# #{rtsU}"
    puts
  end
  (s1names - s2names).each do |sn|
    difffound = true
    segstr = gfa1.send(rt,sn).to_s
    if out_script
      puts "gfa.rm(#{sn.inspect})"
    else
      puts "<\t[#{rts}/exclusive]\t#{segstr}"
    end
  end
  (s2names - s1names).each do |sn|
    difffound = true
    segstr = gfa2.send(rt,sn).to_s
    if out_script
      puts "gfa << #{segstr.inspect}"
    else
      puts ">\t[#{rts}/exclusive]\t#{segstr}"
    end
  end
  (s1names & s2names).each do |sn|
    s1 = gfa1.send(rt,sn)
    s2 = gfa2.send(rt,sn)
    s1.required_fieldnames.each do |fn|
      v1 = s1.send(fn, false)
      v2 = s2.send(fn, false)
      if v1 != v2
        difffound = true
        if out_script
          puts "gfa.#{rt}(#{sn.inspect}).#{fn}=#{v2.inspect}"
        else
          puts "<\t[#{rts}/reqfields/valuediff/#{sn}]\t#{v1}"
          puts ">\t[#{rts}/reqfields/valuediff/#{sn}]\t#{v2}"
        end
      end
    end
    s1f = s1.optional_fieldnames
    s2f = s2.optional_fieldnames
    (s1f - s2f).each do |fn|
      difffound = true
      if out_script
        puts "gfa.#{rt}(#{sn.inspect}).rm_opfield(#{fn.inspect})"
      else
        puts "<\t[#{rts}/optfields/exclusive/#{sn}]\t#{s1.optfield(fn).to_s}"
      end
    end
    (s2f - s1f).each do |fn|
      difffound = true
      v = s2.optfield(fn).to_s
      if out_script
        puts "gfa.#{rt}(#{sn.inspect}) << #{v.inspect}"
      else
        puts ">\t[#{rts}/optfields/exclusive/#{sn}]\t#{v}"
      end
    end
    (s1f & s2f).each do |fn|
      v1 = s1.optfield(fn).to_s
      v2 = s2.optfield(fn).to_s
      if v1 != v2
        difffound = true
        if out_script
          puts "gfa.#{rt}(#{sn.inspect}).#{fn}="+
            "#{s2.optfield(fn).value(false).inspect}"
        else
          puts "<\t[#{rts}/optfields/valuediff/#{sn}]\t#{v1}"
          puts ">\t[#{rts}/optfields/valuediff/#{sn}]\t#{v2}"
        end
      end
    end
  end
  if !difffound
    if out_script
      puts "# ... are identical"
    elsif out_identical
      puts "# #{rtsU} are identical"
    end
  end
  puts if out_script
end

if rt.include?("-s")
  diff_segments_or_paths(gfa1,gfa2, "segment",out_script,out_identical)
end

# TODO: diff of single optfields
if rt.include?("-l")
  difffound = false
  s1names = gfa1.segment_names.sort
  s2names = gfa2.segment_names.sort
  if out_script
    puts "# Links"
    puts
  end
  difflinks1 = []
  (s1names - s2names).each do |sn|
    difffound = true
    [:B, :E].each {|et| difflinks1 += gfa1.links_of([sn, et])}
  end
  difflinks1.uniq.each do |l|
    if out_script
      puts "gfa.rm(gfa.link(#{l.from_end.inspect}, #{l.to_end.inspect}))"
    else
      puts "<\t[links/exclusive_segments]\t#{l.to_s}"
    end
  end
  difflinks2 = []
  (s2names - s1names).each do |sn|
    difffound = true
    [:B, :E].each {|et| difflinks2 += gfa2.links_of([sn, et])}
  end
  difflinks2.uniq.each do |l|
    if out_script
      puts "gfa << #{l.to_s.inspect}"
    else
      puts ">\t[links/exclusive_segments]\t#{l.to_s}"
    end
  end
  difflinks1b = []
  difflinks2b = []
  (s1names & s2names).each do |sn|
    [:B, :E].each do |et|
      l1 = gfa1.links_of([sn, et])
      l2 = gfa2.links_of([sn, et])
      d1 = l1 - l2
      d2 = l2 - l1
      if !d1.empty?
        difffound = true
        difflinks1b += d1
      end
      if !d2.empty?
        difffound = true
        difflinks2b += d2
      end
    end
  end
  (difflinks1b-difflinks1).uniq.each do |l|
    if out_script
      puts "gfa.rm(gfa.link(#{l.from_end.inspect}, #{l.to_end.inspect}))"
    else
      puts "<\t[links/different]\t#{l.to_s}"
    end
  end
  (difflinks2b-difflinks2).uniq.each do |l|
    if out_script
      puts "gfa << #{l.to_s.inspect}"
    else
      puts ">\t[links/different]\t#{l.to_s}"
    end
  end
  if !difffound
    if out_script
      puts "# ... are identical"
    elsif out_identical
      puts "# Links are identical"
    end
  end
  puts if out_script
end

# TODO: this code is similar to -l; make generic and merge
if rt.include?("-c")
  difffound = false
  s1names = gfa1.segment_names.sort
  s2names = gfa2.segment_names.sort
  cexcl1 = []
  (s1names - s2names).each do |sn|
    difffound = true
    cexcl1 += gfa1.contained_in(sn)
    cexcl1 += gfa1.containing(sn)
  end
  cexcl1.uniq.each do |c|
    if out_script
      puts "gfa.rm(gfa.containment(#{c.from.inspect}, #{c.to.inspect}))"
    else
      puts "<\t[contaiments/exclusive_segments]\t#{c.to_s}"
    end
  end
  cexcl2 = []
  (s2names - s1names).each do |sn|
    difffound = true
    cexcl2 += gfa2.contained_in(sn)
    cexcl2 += gfa2.containing(sn)
  end
  cexcl2.uniq.each do |c|
    if out_script
      puts "gfa << #{c.to_s.inspect}"
    else
      puts ">\t[contaiments/exclusive_segments]\t#{c.to_s}"
    end
  end
  cdiff1 = []
  cdiff2 = []
  (s1names & s2names).each do |sn|
    c1 = gfa1.contained_in(sn)
    c2 = gfa2.contained_in(sn)
    c1 += gfa1.containing(sn)
    c2 += gfa2.containing(sn)
    d1 = c1 - c2
    d2 = c2 - c1
    if !d1.empty?
      difffound = true
      cdiff1 += d1
    end
    if !d2.empty?
      difffound = true
      cdiff2 += d2
    end
  end
  (cdiff1-cexcl1).uniq.each do |l|
    if out_script
      puts "gfa.rm(gfa.containment(#{l.from.inspect}, #{l.to.inspect}))"
    else
      puts "<\t[containments/different]\t#{l.to_s}"
    end
  end
  (cdiff2-cexcl2).uniq.each do |l|
    if out_script
      puts "gfa << #{l.to_s.inspect}"
    else
      puts ">\t[containments/different]\t#{l.to_s}"
    end
  end
  if !difffound
    if out_script
      puts "# ... are identical"
    elsif out_identical
      puts "# Containments are identical"
    end
  end
  puts if out_script
end

if rt.include?("-p")
  diff_segments_or_paths(gfa1,gfa2,"path",out_script,out_identical)
end

if out_script
  puts
  puts "# Output graph"
  puts "puts gfa"
end
