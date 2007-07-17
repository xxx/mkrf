require 'rubygems'
require 'mkrf'

Mkrf::Generator.new('bang', ["*.cpp"]) do |g|
  g.ldshared << ' -L/usr/lib -lgcc -lstdc++'
end