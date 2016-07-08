require_relative "../lib/rgfatools.rb"
require "test/unit"

class TestRGFAToolsEdit < Test::Unit::TestCase

  def test_delete_low_coverate_segments
    gfa = ["S\t0\t*\tRC:i:600\tLN:i:100",
           "S\t1\t*\tRC:i:6000\tLN:i:100",
           "S\t2\t*\tRC:i:60000\tLN:i:100"].to_rgfa
    assert_equal(["0","1","2"], gfa.segment_names)
    gfa.delete_low_coverage_segments(10)
    assert_equal(["1","2"], gfa.segment_names)
    assert_nothing_raised { gfa.send(:validate_connect) }
    gfa.delete_low_coverage_segments(100)
    assert_equal(["2"], gfa.segment_names)
    assert_nothing_raised { gfa.send(:validate_connect) }
    gfa.delete_low_coverage_segments(1000)
    assert_equal([], gfa.segment_names)
    assert_nothing_raised { gfa.send(:validate_connect) }
  end

  def test_compute_copy_numbers
    gfa = ["S\t0\t*\tRC:i:10\tLN:i:100",
           "S\t1\t*\tRC:i:1000\tLN:i:100",
           "S\t2\t*\tRC:i:2000\tLN:i:100",
           "S\t3\t*\tRC:i:3000\tLN:i:100"].to_rgfa
    assert_nothing_raised { gfa.compute_copy_numbers(9) }
    assert_equal(0, gfa.segment!("0").cn)
    assert_equal(1, gfa.segment!("1").cn)
    assert_equal(2, gfa.segment!("2").cn)
    assert_equal(3, gfa.segment!("3").cn)
  end

  def test_apply_copy_number
    gfa = ["S\t0\t*\tRC:i:10\tLN:i:100",
           "S\t1\t*\tRC:i:1000\tLN:i:100",
           "S\t2\t*\tRC:i:2000\tLN:i:100",
           "S\t3\t*\tRC:i:3000\tLN:i:100"].to_rgfa
    assert_equal(["0","1","2","3"], gfa.segment_names)
    gfa.compute_copy_numbers(9)
    gfa.apply_copy_numbers
    assert_equal(["1","2","3","2b","3b","3c"], gfa.segment_names)
    gfa.compute_copy_numbers(9)
    assert(gfa.segments.map(&:cn).all?{|cn|cn == 1})
    assert_nothing_raised { gfa.send(:validate_connect) }
  end

  def test_linear_path_merging
    s = ["S\t0\tACGA",
         "S\t1\tACGA",
         "S\t2\tACGA",
         "S\t3\tACGA"]
    l = ["L\t0\t+\t1\t+\t1M",
         "L\t1\t+\t2\t-\t1M",
         "L\t2\t-\t3\t+\t1M"]
    gfa = RGFA.new
    (s + l).each {|line| gfa << line }
    gfa.merge_linear_path([["0", :E],["1", :E],["2", :B],["3", :E]])
    assert_nothing_raised {gfa.segment!("0_1_2^_3")}
    assert_equal("ACGACGACGTCGA", gfa.segment("0_1_2^_3").sequence)
  end

  def test_linear_path_merge_all
    s = ["S\t0\t*",
         "S\t1\t*",
         "S\t2\t*",
         "S\t3\t*"]
    l = ["L\t0\t+\t1\t+\t1M",
         "L\t1\t+\t2\t-\t1M",
         "L\t2\t-\t3\t+\t1M"]
    gfa = RGFA.new
    (s + l).each {|line| gfa << line }
    gfa.merge_linear_paths
    assert_equal(["0_1_2^_3"], gfa.segment_names)
    l = ["L\t0\t+\t1\t+\t1M",
         "L\t0\t+\t2\t+\t1M",
         "L\t1\t+\t2\t-\t1M",
         "L\t2\t-\t3\t+\t1M"].map(&:to_rgfa_line)
    gfa = RGFA.new
    (s + l).each {|line| gfa << line }
    gfa.merge_linear_paths
    assert_equal(["0","3","1_2^"], gfa.segments.map(&:name))
  end

end
