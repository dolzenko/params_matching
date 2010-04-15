%w(../
   ../../lib).each { |load_path| $LOAD_PATH.unshift(File.expand_path(load_path, __FILE__)) }


require "should_yield"

require "params_matching"

Spec::Runner.configure do |config|
  config.include ShouldYield::Expectations
end
