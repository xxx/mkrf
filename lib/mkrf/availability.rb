require 'rbconfig'
require 'logger'

module Mkrf
  
  # The +Availability+ class is concerned with libraries, headers, and
  # functions. It can be easily wrapped (see <tt>Mkrf::Generator</tt> for an
  # example) and should be able to be used as a basis for a variety of programs
  # which need to determine functionality based on what libraries are available
  # on the current system.
  class Availability
    DEFAULT_INCLUDES = [Config::CONFIG['includedir'], Config::CONFIG["archdir"],
                        Config::CONFIG['sitelibdir'], "."]
                        
    # These really shouldn't be static like this..
    TEMP_SOURCE_FILE = "temp_source.c"
    TEMP_EXECUTABLE = "temp_executable"
    
    attr_reader :headers, :loaded_libs, :includes, :logger, :defines
    
    # Create a new Availability instance.
    #
    # Valid keys for the options hash include:
    # * <tt>:loaded_libs</tt> -- libraries to load by default
    # * <tt>:library_paths</tt> -- libraries paths to include by default
    # * <tt>:headers</tt> -- headers to load by default
    # * <tt>:compiler</tt> -- which compiler to use when determining availability
    # * <tt>:includes</tt> -- directories that should be searched for include files
    def initialize(options = {})      
      @loaded_libs = (options[:loaded_libs] || Config::CONFIG["LIBS"].gsub('-l', '').split).to_a
      @library_paths = (options[:library_paths] || "").to_a
      # Not sure what COMMON_HEADERS looks like when populated
      @headers = options[:headers] || [] # Config::CONFIG["COMMON_HEADERS"]
      @compiler = options[:compiler] || Config::CONFIG["CC"]
      @includes = (options[:includes] || DEFAULT_INCLUDES).to_a
      @logger = Logger.new('mkrf.log')
      @defines = []
    end
    
    # Include a library in the list of available libs. Returns +false+ if the
    # library is not available. Returns non-false otherwise.
    #
    # Params:
    # * <tt>library</tt> -- the library to be included as a string.
    # * <tt>function</tt> -- a method to base the inclusion of the library on. +main+ by default.
    # * <tt>paths</tt> -- an optional list of search paths if the library is not found in the default paths.
    def include_library(library, function = "main", *paths)
      paths.each do |library_dir|
        @library_paths << library_dir
      end
      @loaded_libs << library if has_library?(library, function)
    end
    
    # Include a header in the list of availiable headers. Returns +false+ if the
    # header is not available. Returns non-false otherwise. If the header is
    # found, the preprocessor constant HAVE_BLAH is defined where BLAH is the name
    # of the header in uppercase without the file extension.
    #
    # Params:
    # * <tt>header</tt> -- the name of the header to be included as a string.
    # * <tt>paths</tt> -- an optional list of search paths if the header is not found in the default paths.
    def include_header(header, *paths)
      @headers << header if has_header?(header, *paths)
    end
    
    # Returns a boolean whether indicating whether the library can be found 
    # by attempting to reference the function passed (+main+ by default).
    #
    # Params:
    # * <tt>library</tt> -- the library to be included as a string
    # * <tt>function</tt> -- a method to base the inclusion of the library on. +main+ by default.
    # * <tt>paths</tt> -- an optional list of search paths if the library is not found in the default paths
    def has_library?(library, function = "main", *paths)
      logger.info "Checking for library: #{library}"
      return true if library_already_loaded?(library)
      return true if RUBY_PLATFORM =~ /mswin/ # TODO: find a way on windows
      # Should this be only found_library? or a specialized version with
      # path searching?
      found_library?(library, function)
    end
    
    # Returns +true+ if the header is found in the default search path or in
    # optional paths passed as an argument, +false+ otherwise. If the header is
    # found, the preprocessor constant HAVE_BLAH is defined where BLAH is the name
    # of the header in uppercase without the file extension.
    #
    # Params:
    # * <tt>header</tt> -- the header to be searched for
    # * <tt>paths</tt> -- an optional list of search paths if the header is not found in the default paths
    def has_header?(header, *paths)
      if header_already_loaded?(header) || header_can_link?(header) || 
                     header_found_in_paths?(header, paths)
        defines << format("HAVE_%s", header.tr("a-z./\055", "A-Z___"))
        return true 
      end
      
      logger.warn "Header not found: #{header}"
      return false
    end
    
    # Returns +true+ if the function is able to be called based on libraries and
    # headers currently loaded. Returns +false+ otherwise.
    #
    # Params:
    # * <tt>function</tt> -- the function to check for
    def has_function?(function)
      if can_link?(simple_call(function)) or can_link?(simple_reference(function))
        logger.info "Function found: #{function}()"
        return true
      else
        logger.warn "Function not found: #{function}()"
        return false
      end
    end
    
    # Returns the result of an attempt to compile and link the function body
    # passed in
    def can_link?(function_body)
      silence_command_line do
        create_source(function_body)
        system(link_command)
      end
    ensure
      FileUtils.rm_f TEMP_SOURCE_FILE
      FileUtils.rm_f TEMP_EXECUTABLE
    end
    
    def with_headers(*args, &b)
      with_stackable_attribute('headers', *args, &b)
    end
    
    def with_loaded_libs(*args, &b)
      with_stackable_attribute('loaded_libs', *args, &b)
    end
    
    def with_includes(*args, &b)
      with_stackable_attribute('includes', *args, &b)
    end
    
    # Returns a string of libraries formatted for compilation
    def library_compile_string
      if RUBY_PLATFORM =~ /mswin/
        @loaded_libs.join(' ')
      else
        @loaded_libs.collect {|l| "-l#{l}"}.join(' ')
      end
    end
    
    # Returns a string of libraries directories formatted for compilation
    def library_paths_compile_string
      if RUBY_PLATFORM =~ /mswin/
        @library_paths.collect {|l| "/libpath:#{l}"}.join(' ')
      else
        @library_paths.collect {|l| "-L#{l}"}.join(' ')
      end
    end

    def ldshared_string
      if RUBY_PLATFORM =~ /mswin/
        "link -nologo -incremental:no -debug -opt:ref -opt:icf -dll"
      else
        Config::CONFIG['LDSHARED']
      end
    end

    def ld_outfile(filename) # :nodoc:
      if RUBY_PLATFORM =~ /mswin/
        "-out:#{filename}"
      else
        "-o #{filename}"
      end
    end

    # Returns a string of include directories formatted for compilation
    def includes_compile_string
      @includes.collect {|i| "-I#{i}"}.join(' ')
    end
    
    # Takes the name of an executable and an optional set of paths to search.
    # If no paths are given, the environmental path is used by default.
    # Returns the absolute path to an executable, or nil if not found.
    def find_executable(bin, *paths)
      paths = ENV['PATH'].split(File::PATH_SEPARATOR) if paths.empty?
      paths.each do |path|
        file = File.join(path, bin)
        return file if File.executable?(file)
      end
      return nil
    end
    
    private
    
    def found_library?(library, function)
      library_found = with_loaded_libs(library) {
        has_function? function
      }
      
      library_found ? logger.info("Library found: #{library}") : 
                        logger.warn("Library not found: #{library}")
      
      library_found
    end
    
    def header_can_link?(header)
      has_header = with_headers(header) {
        can_link?(simple_include(header))
      }
      
      if has_header
        logger.info("Header found: #{header}")
        return true
      end 
    end
    
    def library_already_loaded?(library)
      if @loaded_libs.include? library
        logger.info "Library already loaded: #{library}" 
        return true
      end
      
      return false
    end
    
    def header_already_loaded?(header)
      if @headers.include? header
        logger.info("Header already loaded: #{header}")
        return true
      end 
      
      return false
    end
    
#    def library_found_in_paths?(library, paths)
#      paths.each do |include_path|
#
#        if with_libs(include_path) { library_can_link?(header) }
#          @libspath << include_path
#          return true
#        end
#      end
#      
#      return false
# 
#    end

    def header_found_in_paths?(header, paths)
      paths.each do |include_path|
        if with_includes(include_path) { header_can_link?(header) }
          @includes << include_path
          return true
        end
      end
      
      return false
    end
    
    def with_stackable_attribute(attribute, *args)
      args = args.to_a
      instance_variable_set("@#{attribute}", 
                            instance_variable_get("@#{attribute}") + args)
      value = yield
      instance_variable_set("@#{attribute}", 
                            instance_variable_get("@#{attribute}") - args)
      return value
    end
    
    def header_include_string
      @headers.collect {|header| "#include <#{header}>"}.join('\n')
    end

    def link_command
      # This current implementation just splats the library_paths in
      # unconditionally.  Is this problematic?
      "#{@compiler} -o #{TEMP_EXECUTABLE} #{library_paths_compile_string}" +
      " #{library_compile_string} #{includes_compile_string}" +
      " #{TEMP_SOURCE_FILE}"
    end

    # Creates a temporary source file with the string passed
    def create_source(src)
      File.open(TEMP_SOURCE_FILE, "w+") do |f|
        f.write(src)
      end
    end
        
    # Basic skeleton for calling a function
    def simple_call(func)
      src = <<-SRC
        #{header_include_string}
        int main() { return 0; }
        int t() { #{func}(); return 0; }
      SRC
    end
    
    # Basic skeleton for referencing a function
    def simple_reference(func)
      src = <<-SRC
        #{header_include_string}
        int main() { return 0; }
        int t() { void ((*volatile p)()); p = (void ((*)()))#{func}; return 0; }
      SRC
    end
    
    # skeleton for testing includes
    def simple_include(header)
      src = <<-SRC
        #{header_include_string}
        #include <#{header}>
        int main() { return 0; }
      SRC
    end
        
    def silence_command_line
      yield and return if $debug
      silence_stream(STDERR) do
        silence_stream(STDOUT) do
          yield
        end
      end
    end
    
    # silence_stream taken from Rails ActiveSupport reporting.rb
    
    # Silences any stream for the duration of the block.
    #
    #   silence_stream(STDOUT) do
    #     puts 'This will never be seen'
    #   end
    #
    #   puts 'But this will'
    def silence_stream(stream)
      old_stream = stream.dup
      stream.reopen(RUBY_PLATFORM =~ /mswin/ ? 'NUL:' : '/dev/null')
      stream.sync = true
      yield
    ensure
      stream.reopen(old_stream)
    end
    
  end
end
