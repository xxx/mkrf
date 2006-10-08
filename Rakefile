require 'rake'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rubygems'

$:.unshift(File.dirname(__FILE__) + "/lib")
require 'mkrf'

PKG_NAME      = 'mkrf'
PKG_VERSION   = Mkrf::VERSION
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

RELEASE_NAME  = "REL #{PKG_VERSION}"

RUBY_FORGE_PROJECT = "mkrf"
RUBY_FORGE_USER    = "kevinclark"


task :default => ["test:units"]

namespace :test do
  
  desc "Run basic tests"
  Rake::TestTask.new("units") { |t|
    t.pattern = 'test/unit/test_*.rb'
    t.verbose = true
    t.warning = true
  }
  
  desc "Run integration tests"
  Rake::TestTask.new("integration") { |t|
    t.pattern = 'test/integration/test_*.rb'
    t.verbose = true
    t.warning = true
  }
  
  namespace :samples do
    
    BASE_DIR = File.dirname(__FILE__) + '/test/sample_files'
    
    SAMPLE_DIRS = {
      :trivial => BASE_DIR + '/libtrivial/',
      :syck => BASE_DIR + '/syck-0.55/ext/ruby/ext/syck/',
      :libxml => BASE_DIR + '/libxml-ruby-0.3.8/ext/xml/'
    }
    
    task :default => [:all]
    
    desc "Try to compile all of the sample extensions"
    task :all => [:trivial, :libxml, :syck]
    
    desc "Try to compile a trivial extension"
    task :trivial do
      sh "cd #{SAMPLE_DIRS[:trivial]}; ruby extconf.rb; rake"
    end
    
    desc "Try to compile libxml"
    task :libxml do
      sh "cd #{SAMPLE_DIRS[:libxml]}; ruby extconf.rb; rake"
    end
    
    desc "Try to compile syck"
    task :syck do
      sh "cd #{SAMPLE_DIRS[:syck]}; ruby extconf.rb; rake"
    end
    
    desc "Clean up after sample tests"
    task :clobber do
      if ENV['PROJECT']
        if File.exist?(SAMPLE_DIRS[ENV['PROJECT'].to_sym] + "/Rakefile")
          sh "cd #{SAMPLE_DIRS[ENV['PROJECT'].to_sym]}; rake clobber; rm Rakefile"
        end
      else
        SAMPLE_DIRS.each_value do |test_dir|
          next unless File.exist?(test_dir + "/Rakefile")
          sh "cd #{test_dir}; rake clobber; rm Rakefile"
        end
      end
    end
    
  end  

end

Rake::RDocTask.new do |rd|
  rd.main = "README"
  rd.rdoc_files.include("README", "lib/**/*.rb")
end
  
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
  s.rdoc_options << '--main' << 'README' << '--title' << 'mkrf'
  s.requirements << 'rake'
  s.require_path = 'lib'
  s.autorequire = 'mkrf'
  
  s.extra_rdoc_files = [ "README", "MIT-LICENSE", "CHANGELOG" ]

  s.files = [ "Rakefile", "README", "CHANGELOG", "MIT-LICENSE" ]
  s.files = s.files + Dir.glob( "lib/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
  s.files = s.files + Dir.glob( "test/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
end
  
Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end
