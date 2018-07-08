ENV['ENV'] ||= 'test'
Bundler.require(:default, ENV['ENV'])
require "lxd-client"
require "support/helpers/unit_helpers"

RSpec.configure do |config|
  config.color= true
  config.order= :rand
  config.default_formatter = 'doc'
  config.profile_examples = 10
  config.warnings = true
  config.raise_errors_for_deprecations!
  config.disable_monkey_patching!

  config.include SpecHelper::UnitHelpers
end