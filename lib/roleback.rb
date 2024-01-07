require "roleback/version"
require 'roleback/definitions/load'
Dir["#{File.dirname(__FILE__)}/roleback/**/*.rb"].each { |f| load(f) }

module Roleback
	class Error < StandardError; end
	class NotConfiguredError < StandardError; end
	class BadConfiguration < StandardError; end
	class BadMatch < StandardError; end
end
