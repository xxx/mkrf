require 'rubygems'
require 'rbconfig'
require 'rake/tasklib'


module Mkrf
  
  # +Generator+ is concerned with taking configuration for an extension
  # and writing a +Rakefile+ to the local filesystem which will later be
  # used to build the extension.
  #
  # You will typically only create one +Generator+ per <tt>extconf.rb</tt>
  # file, which in turn will generate a Rakefile for building one extension
  # module.
  #
  # = Usage
  #
  # In the most basic usage, +Generator+ simply takes the name of the library
  # to compile:
  #
  #   require 'mkrf'
  #   Mkrf::Generator.new('libtrivial')
  #
  # Configuration of the build can be passed to the +Generator+ constructor
  # as a block:
  #
  #   Mkrf::Generator.new('libxml') do |g|
  #     g.include_library('socket','socket')
  #     g.include_header('libxml/xmlversion.h',
  #                      '/opt/include/libxml2',
  #                      '/usr/local/include/libxml2',
  #                      '/usr/include/libxml2')
  #   end
  #  
  class Generator
    include Rake
    
    CONFIG = Config::CONFIG
    
    # Any extra code, given as a string, to be appended to the Rakefile.
    attr_accessor :additional_code
    
    # You may append to these attributes directly in your Generator.new block,
    # for example: <tt>g.object << ' ../common/foo.o ../common/bar.so -lmystuff'</tt> or
    # <tt>g.cflags << ' -ansi -Wall'</tt>
    #
    # Note the extra space at the beginning of those strings.
    attr_accessor :cflags

    # +objects+ is for adding _additional_ object files to the link-edit command -- outside
    # of the ones that correspond to the source files.
    attr_accessor :objects

    # Any additional options you'd like appended to your system-specific linker command
    # (which is used to build the shared library).
    attr_accessor :ldshared

    
    
    # Create a +Generator+ object which writes a Rakefile to the current directory of the local
    # filesystem.
    #
    # Params:
    # * +extension_name+ -- the name of the extension
    # * +source_patterns+ -- an array of patterns describing source files to be compiled. ["*.c"] is the default.
    def initialize(extension_name, source_patterns = ["*.c"], availability_options = {})
      @sources = source_patterns
      @extension_name = extension_name + ".#{CONFIG['DLEXT']}"
      @available = Mkrf::Availability.new(availability_options)
      @defines = []
      
      objects = ''
      ldshared = CONFIG['LDSHARED']
      cflags = "#{CONFIG['CCDLFLAGS']} #{CONFIG['CFLAGS']} #{CONFIG['ARCH_FLAG']}"
      
      yield self if block_given?
      write_rakefile
    end
    
    # An array of the source patterns as single quoted strings
    def sources
      @sources.collect {|s| "'#{s}'"}
    end
    
    # Add a define to the compile string. Example: 
    #
    #   Mkrf::Generator.new('my_library') do |g|    
    #     g.add_define(HAVE_PTHREADS)
    #   end
    #
    # Params:
    # * +defn+ -- string to add to compile time defines
    def add_define(defn)
      @defines.push(defn)
    end
    
    # Include a library in the compile. Returns +false+ if the
    # library is not available. Returns non-false otherwise.
    # Parameters are the same as Mkrf::Availability#include_library
    def include_library(*args)
      @available.include_library(*args)
    end
    
    # Include a header in the compile. Returns +false+ if the header is not
    # available, returns non-false otherwise. As a side effect, a compile
    # time define occurs as +HAVE_+ appended with the name of the header in
    # upper and scored case.
    # Parameters are the same as Mkrf::Availability#include_header
    def include_header(*args)
      @available.include_header(*args)
    end
    
    # Returns +true+ if the function is able to be called based on libraries and
    # headers currently loaded. Returns +false+ otherwise.
    #
    # Params:
    # * <tt>function</tt> -- the function to check for
    def has_function?(function)
      @available.has_function? function
    end
    
    # Returns mkrf's logger instance. You can use this to set logging levels.
    #
    #   Mkrf::Generator.new('libsomethin') do |g|
    #     g.logger.level = Logger::WARN
    #   end
    #
    def logger
      @available.logger
    end
    
    def write_rakefile(filename = "Rakefile") # :nodoc:
      File.open(filename, "w+") do |f|
        f.puts rakefile_contents
      end
      @available.logger.info "Rakefile written"
    end
    
    def defines_compile_string # :nodoc:
      (@defines.collect {|define| "-D#{define}" } +
      @available.headers.collect { |header|
        format("-DHAVE_%s", header.tr("a-z./\055", "A-Z___"))
      }).join(' ')
    end
    
    def rakefile_contents # :nodoc:
      <<-END_RAKEFILE
require 'rake/clean'

CLEAN.include('*.o')
CLOBBER.include('#{@extension_name}', 'mkrf.log')

SRC = FileList[#{sources.join(',')}]
OBJ = SRC.ext('o')
CC = "gcc"

ADDITIONAL_OBJECTS = '#{objects}'

LDSHARED = "#{CONFIG['LDSHARED']} #{ldshared}"

LIBPATH =  '-L"#{CONFIG['rubylibdir']}"'

INCLUDES = "#{@available.includes_compile_string}"

LIBS = "#{@available.library_compile_string}"

CFLAGS = "#{cflags} #{defines_compile_string}"

task :default => ['#{@extension_name}']

rule '.o' => '.c' do |t|
  sh "\#{CC} \#{CFLAGS} \#{INCLUDES} -c -o \#{t.name} \#{t.source}"
end

desc "Build this extension"
file '#{@extension_name}' => OBJ do
  sh "\#{LDSHARED} \#{LIBPATH} -o #{@extension_name} \#{OBJ} \#{ADDITIONAL_OBJECTS} \#{LIBS}"
end

#{additional_code}
      END_RAKEFILE
    end
  end
end
