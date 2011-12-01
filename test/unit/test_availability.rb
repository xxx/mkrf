require File.dirname(__FILE__) + '/../abstract_unit'


class TestAvailability < Test::Unit::TestCase
  def setup
    @fixture_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'fixtures'))
    @avail = Mkrf::Availability.new(:includes => @fixture_path)
  end
  
  def teardown
    FileUtils.rm_f 'mkrf.log'
  end
  
  def test_has_library_should_return_true_when_lib_already_loaded
    @avail =  Mkrf::Availability.new(:loaded_libs => ['sample_library'])
    assert @avail.has_library?('sample_library')
  end

  def test_has_library_should_fail_on_bogus_lib
    assert !@avail.has_library?('bogus_library')
  end
  
  def test_can_link
    @avail.send(:with_headers, 'stdio.h') do
      assert @avail.can_link?(@avail.send(:simple_reference, "printf"))
    end
  end
  
  def test_create_source
    assert_creates_file(Mkrf::Availability::TEMP_SOURCE_FILE) do    
      @avail.send(:create_source, "puts 'Hello World!'")
    end

    source = File.open(Mkrf::Availability::TEMP_SOURCE_FILE).read
    assert_equal "puts 'Hello World!'", source
  ensure
    FileUtils.rm_f Mkrf::Availability::TEMP_SOURCE_FILE
  end
  
  def test_has_header_should_fail_on_bogus_header
    assert !@avail.has_header?('some_fake_header.h')
  end
  
  def test_has_header_should_work_with_basic_headers
    assert @avail.has_header?('stdmkrf.h')
  end
  
  def test_has_header_should_check_many_paths
    assert !@avail.has_header?('header_down_a_directory.h')
    assert @avail.has_header?('header_down_a_directory.h', 
                              File.join(@fixture_path, 'down_a_directory'))
  end
  
  def test_has_header_should_add_define_with_valid_header
    assert @avail.has_header?('stdmkrf.h')
    assert @avail.defines.include?('HAVE_STDMKRF_H'), "Defines: #{@avail.defines.inspect}"
  end
  
  def test_include_header
    assert @avail.has_header?('stdmkrf.h')
    assert !@avail.headers.include?('stdmkrf.h')
    @avail.include_header('stdmkrf.h')
    assert @avail.headers.include?('stdmkrf.h')
  end
  
  # This should really use a trivial lib compiled in fixtures..
  def test_include_library
    assert @avail.has_library?('z')
    assert !@avail.loaded_libs.include?('z')
    @avail.include_library('z')
    assert @avail.loaded_libs.include?('z')
  end
  
  def test_method_missing_should_go_down_chain_when_not_catching_stackable_attributes
    assert_raises(NoMethodError) { @avail.not_a_stackable_attribute }
    assert_raises(NoMethodError) { @avail.with_not_a_stackable_attribute }
  end
  
  def test_find_executable_should_return_nil_when_not_found
    assert_nil @avail.find_executable('fake_executable')
  end
  
  def test_find_executable_should_default_to_search_env_path
    old_path = ENV['PATH']
    ENV['PATH'] = @fixture_path
    expected = File.join(@fixture_path, 'some_binary')
    assert_equal expected, @avail.find_executable('some_binary')
  ensure
    ENV['PATH'] = old_path
  end
  
  def test_find_executable_should_search_given_paths_if_supplied
    expected = File.join(@fixture_path, 'some_binary')
    assert_equal expected, @avail.find_executable('some_binary', @fixture_path)
  end
  
  def test_logging
    @avail.logger.level = Logger::INFO
    assert @avail.include_library('z')
    assert @avail.include_library('z')
    assert !@avail.include_library('bogus_lib')
    assert !@avail.include_header('some_fake_header.h')
    assert @avail.include_header('stdio.h')
    assert !@avail.has_function?('blah_blah_blah')
    assert @avail.has_function?('printf')
    
    source = File.open('mkrf.log').read
    
    
    [ 'Checking for library: z',
      'Library found: z',
      'Library already loaded: z',
      'Library not found: bogus_lib',
      'Header not found: some_fake_header.h',
      'Header found: stdio.h',
      'Function not found: blah_blah_blah()',
      'Function found: printf()'               
    ].each do |log_items|
      assert_match log_items, source
    end    
  end
end

class TestAvailabilityDefaults < Test::Unit::TestCase
  def setup
    @avail = Mkrf::Availability.new
    @config = Config::CONFIG
  end
  
  def test_default_libs_should_be_from_rbconfig
    assert_equal @config["LIBS"].chomp(" "), @avail.library_compile_string
  end
  
  def test_default_compiler_should_be_from_rbconfig
    assert_equal @config["CC"], @avail.send(:instance_variable_get, :@compiler)
  end
  
  def test_default_include_dir_should_be_from_rbconfig
    # Ruby 1.9
    if Config::CONFIG['rubyhdrdir']
      # Have to add exactly what is in the availiability.rb for Ruby 1.9, since
      # there is no special RbConfig::CONFIG field for that
      expected = [RbConfig::CONFIG['includedir'], Config::CONFIG['rubyhdrdir'] +
                  "/" + Config::CONFIG['arch'], RbConfig::CONFIG["archdir"],
                  RbConfig::CONFIG['sitelibdir'], "."]
    else
      expected = [Config::CONFIG['includedir'], Config::CONFIG["archdir"],
                  Config::CONFIG['sitelibdir'], "."]
    end
    assert_equal expected, @avail.send(:instance_variable_get, :@includes)
  end
end
