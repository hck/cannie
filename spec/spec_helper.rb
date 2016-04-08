require 'simplecov'

SimpleCov.start do
  add_filter 'lib/'
end

require 'rubygems'

require 'action_controller'
require 'cannie'

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end
