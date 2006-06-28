require File.dirname(__FILE__) + '/abstract_unit'

class TestAvailability < Test::Unit::TestCase
  def setup
    @avail = Mkrf::Availability.new(:includes => File.join(File.dirname(__FILE__), 'fixtures'))
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
    assert !File.exist?(Mkrf::Availability::TEMP_SOURCE_FILE)

    @avail.send(:create_source, "puts 'Hello World!'")

    assert File.exist?(Mkrf::Availability::TEMP_SOURCE_FILE)

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
    assert @avail.has_header?('header_down_a_directory.h', File.join(File.dirname(__FILE__), 'fixtures', 'down_a_directory'))
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
end