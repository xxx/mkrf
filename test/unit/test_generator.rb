require File.dirname(__FILE__) + '/../abstract_unit'

# stubb this out so we don't overwrite our test rakefile
module Mkrf
  class Generator
    def write_rakefile(file = "Rakefile")
    end
    
    attr_reader :available
  end
end

class TestGenerator < Test::Unit::TestCase
  def setup
    FileUtils.rm_f 'mkrf.log'
  end
  
  def test_default_sources
    g = Mkrf::Generator.new('testlib')
    assert_equal ["'lib/*.c'"], g.sources, "Default sources incorrect"
  end
  
  def test_additional_code
    generator = Mkrf::Generator.new('testlib') do |g|
      g.additional_code = spec_code
    end
    assert_match spec_code, generator.rakefile_contents
  end
  
  def test_logging_levels
    generator = Mkrf::Generator.new('testlib') do |g|
      g.logger.level = Logger::WARN
      g.include_header 'stdio.h'
      g.include_header 'fake_header.h'
    end
    
    logs = File.open('mkrf.log').read
    assert_no_match(/INFO/, logs)
    assert_match(/WARN/, logs)
  end
  
  def test_logging_defaults_to_info_level
    generator = Mkrf::Generator.new('testlib') do |g|
      g.include_header 'stdio.h'
      g.include_header 'fake_header.h'
    end
    
    logs = File.open('mkrf.log').read
    assert_match(/INFO/, logs)
    assert_match(/WARN/, logs)
  end
  
  def test_availability_options_accessible_in_initialize
    generator = Mkrf::Generator.new('testlib', ['lib/*.c'], {:loaded_libs => 'static_ruby'})
    assert_equal ['static_ruby'], generator.available.loaded_libs
  end
  
  def test_additional_objects
    obj_string = 'somedir/somefile.o'
    generator = Mkrf::Generator.new('testlib') do |g|
      g.objects = obj_string
    end
    
    assert_match obj_string, generator.rakefile_contents
  end
  
  protected
  
  def spec_code
    <<-SPEC
    # Create compressed packages
    spec = Gem::Specification.new do |s|
      s.platform = Gem::Platform::RUBY
      s.name = PKG_NAME
      s.summary = "Generate Rakefiles to Build C Extensions to Ruby"
      s.description = %q{This proposed replacement to mkmf generates Rakefiles to build C Extensions.}
      s.version = PKG_VERSION

      s.author = "Kevin Clark"
      s.email = "kevin.clark@gmail.com"
      s.rubyforge_project = RUBY_FORGE_PROJECT
      s.homepage = "http://glu.ttono.us"

      s.has_rdoc = true
      s.requirements << 'rake'
      s.require_path = 'lib'
      s.autorequire = 'mkrf'

      s.files = [ "Rakefile", "README", "CHANGELOG", "MIT-LICENSE" ]
      s.files = s.files + Dir.glob( "lib/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
      s.files = s.files + Dir.glob( "test/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
    end

    Rake::GemPackageTask.new(spec) do |p|
      p.gem_spec = spec
      p.need_tar = true
      p.need_zip = true
    end
    SPEC
  end
end