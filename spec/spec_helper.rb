$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rubygems'
require 'spec'
require 'spec/autorun'
require 'rr'
require 'notes_structured_text_strip_bodies'

Spec::Runner.configure do |config|
  config.mock_with RR::Adapters::Rspec
end
