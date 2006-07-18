require File.dirname(__FILE__) + '/abstract_unit'

class TestSampleProjects < Test::Unit::TestCase
  SAMPLES_DIR = File.dirname(__FILE__) + '/sample_files'
  
  SAMPLE_LIBS = {
    :libtrivial => '/libtrivial/libtrivial.bundle',
    :syck => '/syck-0.55/ext/ruby/ext/syck/syck.bundle',
    :libxml => '/libxml-ruby-0.3.8/ext/xml/libxml_so.bundle'
  }
  
  # Set to true for full command line output
  @@debug = false
  
  def setup
    silence_command_line do
      system('rake test:samples:clean')
    end
  end
  
  def test_that_trivial_lib_compiles
    assert !File.exist?(SAMPLES_DIR + SAMPLE_LIBS[:libtrivial])
    silence_command_line do 
      system('rake test:samples:trivial')
    end
    assert File.exist?(SAMPLES_DIR + SAMPLE_LIBS[:libtrivial])
  end
  
  def test_that_syck_compiles
    assert !File.exist?(SAMPLES_DIR + SAMPLE_LIBS[:syck])
    silence_command_line do 
      system('rake test:samples:syck')
    end
    assert File.exist?(SAMPLES_DIR + SAMPLE_LIBS[:syck])
  end
  
  def test_that_libxml_compiles
    assert !File.exist?(SAMPLES_DIR + SAMPLE_LIBS[:libxml])
    silence_command_line do 
      system('rake test:samples:libxml')
    end
    assert File.exist?(SAMPLES_DIR + SAMPLE_LIBS[:libxml])
  end
end