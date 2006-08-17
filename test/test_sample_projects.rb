require File.dirname(__FILE__) + '/abstract_unit'

class TestSampleProjects < Test::Unit::TestCase
  SAMPLES_DIR = File.dirname(__FILE__) + '/sample_files'
  
  SAMPLE_LIBS = {
    :trivial => '/libtrivial/libtrivial.bundle',
    :syck => '/syck-0.55/ext/ruby/ext/syck/syck.bundle',
    :libxml => '/libxml-ruby-0.3.8/ext/xml/libxml_so.bundle'
  }
  
  # Set to true for full command line output
  @@debug = false
  
  SAMPLE_LIBS.each do |k,v|
    define_method("test_that_#{k}_compiles") do
      silence_command_line do
        system("rake test:samples:clobber PROJECT=#{k}")
      end
      assert_creates_file(SAMPLES_DIR + v) do
        silence_command_line do 
          system("rake test:samples:#{k}")
        end
      end
    end
  end
end