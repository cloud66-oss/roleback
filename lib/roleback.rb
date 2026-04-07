require "roleback/version"
require 'roleback/definitions/load'
# use require instead of load to avoid re-executing already-loaded files
Dir["#{File.dirname(__FILE__)}/roleback/**/*.rb"].each { |f| require(f) }

module Roleback
	class Error < StandardError; end
	class NotConfiguredError < StandardError; end
	class BadConfiguration < StandardError; end
	class BadMatch < StandardError; end
	class InvalidOrMisconfiguredUserClass < StandardError; end
	class MissingRole < StandardError; end
end
