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

if ARGV.size != 2
  STDERR.puts "Compare two GFA files"
  STDERR.puts 
  STDERR.puts "Usage: #$0 [-h] [-s] [-l] [-c] [-p] [-i] <gfa1> <gfa2>"
  STDERR.puts
  STDERR.puts "If a combination of -h,-s,-l,-c and/or -p is specified, then"
  STDERR.puts "only record of the specified type [h=headers, s=segments, "
  STDERR.puts "l=links, c=containments, p=paths] are compared. "
  STDERR.puts "(default: -h -s -l -c -p)"
  STDERR.puts
  STDERR.puts "-i: output if identical"
  exit 1
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
    puts "# Header values are identical" if out_identical
  else
    (h1.keys - h2.keys).each do |k|
      puts "<\t[headers/exclusive]\t#{k.inspect}\t#{h1[k].inspect}"
    end
    (h2.keys - h1.keys).each do |k|
      puts ">\t[headers/exclusive]\t#{k.inspect}\t#{h2[k].inspect}"
    end
    (h1.keys & h2.keys).each do |k|
      v1 = h1[k]
      v2 = h2[k]
      if v1 != v2
        puts "<\t[headers/valuediff/#{k}]\t#{v1}"
        puts ">\t[headers/valuediff/#{k}]\t#{v2}"
      end
    end
  end
end

if rt.include?("-s")
  s1names = gfa1.segment_names.sort
  s2names = gfa2.segment_names.sort
  difffound = false
  (s1names - s2names).each do |sn|
    difffound = true
    puts "<\t[segments/exclusive]\t#{gfa1.segment(sn).to_s}"
  end
  (s2names - s1names).each do |sn|
    difffound = true
    puts ">\t[segments/exclusive]\t#{gfa2.segment(sn).to_s}"
  end
  (s1names & s2names).each do |sn|
    s1 = gfa1.segment(sn)
    s2 = gfa2.segment(sn)
    s1.required_fieldnames.each do |fn|
      v1 = s1.get_field(s1.fieldnames.index(fn), false)
      v2 = s2.get_field(s2.fieldnames.index(fn), false)
      if v1 != v2
        difffound = true
        puts "<\t[segments/reqfields/valuediff/#{sn}]\t#{v1}"
        puts ">\t[segments/reqfields/valuediff/#{sn}]\t#{v2}"
      end
    end
    s1f = s1.optional_fieldnames
    s2f = s2.optional_fieldnames
    (s1f - s2f).each do |fn|
      difffound = true
      puts "<\t[segments/optfields/exclusive/#{sn}]\t#{s1.optfield(fn).to_s}"
    end
    (s2f - s1f).each do |fn|
      difffound = true
      puts ">\t[segments/optfields/exclusive/#{sn}]\t#{s2.optfield(fn).to_s}"
    end
    (s1f & s2f).each do |fn|
      v1 = s1.optfield(fn).to_s
      v2 = s2.optfield(fn).to_s
      if v1 != v2
        difffound = true
        puts "<\t[segments/optfields/valuediff/#{sn}]\t#{v1}"
        puts ">\t[segments/optfields/valuediff/#{sn}]\t#{v2}"
      end
    end
  end
  if !difffound and out_identical
    puts "# Segments are identical"
  end
end

# TODO: diff of single optfields
if rt.include?("-l")
  difffound = false
  s1names = gfa1.segment_names.sort
  s2names = gfa2.segment_names.sort
  difflinks1 = []
  (s1names - s2names).each do |sn|
    difffound = true
    [:B, :E].each {|et| difflinks1 += gfa1.links_of([sn, et])}
  end
  difflinks1.uniq.each do |l|
    puts "<\t[links/exclusive_segments]\t#{l.to_s}"
  end
  difflinks2 = []
  (s2names - s1names).each do |sn|
    difffound = true
    [:B, :E].each {|et| difflinks2 += gfa2.links_of([sn, et])}
  end
  difflinks2.uniq.each do |l|
    puts ">\t[links/exclusive_segments]\t#{l.to_s}"
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
    puts "<\t[links/different]\t#{l.to_s}"
  end
  (difflinks2b-difflinks2).uniq.each do |l|
    puts ">\t[links/different]\t#{l.to_s}"
  end
  if !difffound and out_identical
    puts "# Links are identical"
  end
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
    puts "<\t[contaiments/exclusive_segments]\t#{c.to_s}"
  end
  cexcl2 = []
  (s2names - s1names).each do |sn|
    difffound = true
    cexcl2 += gfa2.contained_in(sn)
    cexcl2 += gfa2.containing(sn)
  end
  cexcl2.uniq.each do |c|
    puts ">\t[contaiments/exclusive_segments]\t#{c.to_s}"
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
    puts "<\t[containments/different]\t#{l.to_s}"
  end
  (cdiff2-cexcl2).uniq.each do |l|
    puts ">\t[containments/different]\t#{l.to_s}"
  end
  if !difffound and out_identical
    puts "# Containments are identical"
  end
end

# TODO: this code is identical to -s; make generic and merge
if rt.include?("-p")
  s1names = gfa1.path_names.sort
  s2names = gfa2.path_names.sort
  difffound = false
  (s1names - s2names).each do |sn|
    difffound = true
    puts "<\t[paths/exclusive]\t#{gfa1.path(sn).to_s}"
  end
  (s2names - s1names).each do |sn|
    difffound = true
    puts ">\t[paths/exclusive]\t#{gfa2.path(sn).to_s}"
  end
  (s1names & s2names).each do |sn|
    s1 = gfa1.path(sn)
    s2 = gfa2.path(sn)
    s1.required_fieldnames.each do |fn|
      v1 = s1.get_field(s1.fieldnames.index(fn), false)
      v2 = s2.get_field(s2.fieldnames.index(fn), false)
      if v1 != v2
        difffound = true
        puts "<\t[paths/reqfields/valuediff/#{sn}]\t#{v1}"
        puts ">\t[paths/reqfields/valuediff/#{sn}]\t#{v2}"
      end
    end
    s1f = s1.optional_fieldnames
    s2f = s2.optional_fieldnames
    (s1f - s2f).each do |fn|
      difffound = true
      puts "<\t[paths/optfields/exclusive/#{sn}]\t#{s1.optfield(fn).to_s}"
    end
    (s2f - s1f).each do |fn|
      difffound = true
      puts ">\t[paths/optfields/exclusive/#{sn}]\t#{s2.optfield(fn).to_s}"
    end
    (s1f & s2f).each do |fn|
      v1 = s1.optfield(fn).to_s
      v2 = s2.optfield(fn).to_s
      if v1 != v2
        difffound = true
        puts "<\t[paths/optfields/valuediff/#{sn}]\t#{v1}"
        puts ">\t[paths/optfields/valuediff/#{sn}]\t#{v2}"
      end
    end
  end
  if !difffound and out_identical
    puts "# Paths are identical"
  end
end
