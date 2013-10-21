require 'simplecov'

SimpleCov.start

require 'rubygems'

require 'active_support/concern'
require 'action_controller'
require 'cannie'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end
