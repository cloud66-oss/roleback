module Roleback
	def self.configure(options = {}, &block)
		@config = ::Roleback::Builder.new(options, &block).build if block_given?
		@config.construct!

		@config
	end

	def self.configuration
		@config || (raise ::Roleback::NotConfiguredError)
	end

	class Configuration
		attr_reader :roles

		def initialize(options = {})
			@options = options
			@roles = {}
		end

		def construct!
			# go through all roles and find their parents
			@roles.each do |name, role|
				parent = role.parent

				if parent
					found_parent = @roles[parent]
					raise ::Roleback::BadConfiguration, "Role #{parent} not found" unless found_parent
					role.instance_variable_set(:@parent, found_parent)
				end
			end

			# go through all roles, and inherit their parents' rules
			@roles.each do |name, role|
				role.inherit
			end
		end
	end

	class Builder
		def initialize(options = {}, &block)
			@options = options
			@config = ::Roleback::Configuration.new(options)
			@parent = nil

			instance_eval(&block) if block_given?
		end

		def build
			@config
		end

		def role(name, options = {}, &block)
			roles = @config.instance_variable_get(:@roles) || {}

			raise ::Roleback::BadConfiguration, "Role #{name} already defined" if roles[name]

			validate_options!(options)

			parent = options[:parent]

			role = ::Roleback::Definitions::Role.new(name, parent: parent)
			role.instance_eval(&block) if block_given?

			roles[name] = role
			@config.instance_variable_set(:@roles, roles)

			role
		end

		def validate_options!(options)
			raise ::Roleback::BadConfiguration, "Invalid options" if options.keys.any? { |k| ![:parent].include?(k) }
		end
	end
end
