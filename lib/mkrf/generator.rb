require 'rubygems'
require 'rbconfig'
require 'rake/tasklib'

module Mkrf
  
  # +Generator+ is concerned with taking configuration for an extension
  # and writing a +Rakefile+ to the local filesystem to build the extension.
  #
  # = Usage
  # In the most basic usage, +Generator+ simply takes the name of the library
  # to compile:
  #
  #   require 'mkrf'
  #   Mkrf::Generator.new('libtrivial_so.bundle')
  #
  # Configuration of the build can be passed to the +Generator+ constructor
  # as a block:
  #
  #   Mkrf::Generator.new('libxml_so.bundle', '*.c') do |g|
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
    
    # Create a new generator which will write a new +Rakefile+ to the local
    # filesystem.
    #
    # Params:
    # * +library_location+ -- the location of the library to be compiled on the local filesystem
    # * +source_patterns+ -- a pattern describing source files to be compiled, "lib/*.c" by default
    def initialize(library_location, *source_patterns)
      @sources = source_patterns || ["lib/*.c"]
      @library_location = library_location
      @available = Mkrf::Availability.new(:includes => [CONFIG['includedir'], CONFIG["archdir"],
                                                        CONFIG['sitelibdir'], "."] )
      @defines = []
      
      yield self if block_given?
      write_rakefile
    end
    
    # Add a new pattern to the list of source patterns
    def add_source(pattern)
      @sources << pattern
    end
    
    # An array of the source patterns as single quoted strings
    def sources
      @sources.collect {|s| "'#{s}'"}
    end
    
    # Add a define to the compile string. Example: 
    #
    #   Mkrf::Generator.new('my_library.bundle') do |g|    
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
    
    def write_rakefile(filename = "Rakefile") # :nodoc:
      File.open(filename, "w+") do |f|
        f.puts rakefile_contents
      end
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
        CLOBBER.include('#{@library_location}')
        
        SRC = FileList[#{sources.join(',')}]
        OBJ = SRC.ext('o')
        CC = "gcc"

        LDSHARED = "#{CONFIG['LDSHARED']}"
        LIBPATH =  '-L"/usr/local/lib"'
        
        INCLUDES = "#{@available.includes_compile_string}"

        LIBS = "#{@available.library_compile_string}"

        CFLAGS   = "#{CONFIG['CCDLFLAGS']} #{CONFIG['CFLAGS']} #{CONFIG['ARCH_FLAG']} #{defines_compile_string}"
        
        task :default => ['#{@library_location}']

        rule '.o' => '.c' do |t|
          sh "\#{CC} \#{CFLAGS} \#{INCLUDES} -c -o \#{t.name} \#{t.source}"
        end

        rule '.so' => '.o' do |t|
          sh "\#{LDSHARED} \#{LIBPATH} -o \#{OBJ} \#{LOCAL_LIBS} \#{LIBS}"
        end

        file '#{@library_location}' => OBJ do
          sh "\#{LDSHARED} \#{LIBPATH} -o #{@library_location} \#{OBJ} \#{LIBS}"
        end
      END_RAKEFILE
    end
  end
end