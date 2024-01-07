require_relative 'rule_based'
Dir["#{File.dirname(__FILE__)}/roleback/**/*.rb"].each { |f| load(f) }
