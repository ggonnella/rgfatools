require_relative "../lib/gfatools.rb"
require "test/unit"

class TestGFATools < Test::Unit::TestCase

  def test_basics
    assert_nothing_raised { GFA.new }
    assert_nothing_raised { GFA.included_modules.include?(GFATools) }
  end

end
