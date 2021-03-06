$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
require File.dirname(__FILE__) + '/../lib/mkrf'

$debug = false

class Test::Unit::TestCase
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
  
  protected
  
  def assert_creates_file(file)
    assert !File.exist?(file), "#{file} already exists!"
    yield
    assert File.exist?(file), "#{file} wasn't created!"
  end
  
end