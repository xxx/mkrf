require File.dirname(__FILE__) + '/abstract_unit'

# stubb this out so we don't overwrite our test rakefile
module Mkrf
  class Generator
    def write_rakefile(file = "Rakefile")
    end
  end
end

class TestGenerator < Test::Unit::TestCase
  def test_default_sources
    g = Mkrf::Generator.new('testlib')
    assert_equal ["'lib/*.c'"], g.sources, "Default sources incorrect"
  end
end