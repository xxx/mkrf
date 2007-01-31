require 'rubygems'
require 'mkrf'

Mkrf::Generator.new('trivial') do |g|
  g.include_library('', '', '/usr/local/lib')
end
