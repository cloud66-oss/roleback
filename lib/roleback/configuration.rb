module Roleback
	def self.define(options = {}, &block)
		@config = ::Roleback::Builder.new(options, &block).build if block_given?
		@config.construct!

		# is there a ::User class defined?
		if options[:user_class]
			@user_class = options[:user_class]
		elsif defined?(::User)
			@user_class = ::User
		else
			@user_class = nil
		end

		# extend the user class
		::Roleback::UserExtension.extend!(@user_class) if @user_class

		@config
	end

	def self.configuration
		@config || (raise ::Roleback::NotConfiguredError)
	end

	def self.any
		::Roleback::ANY
	end

	def self.allow
		::Roleback::ALLOW
	end

	def self.deny
		::Roleback::DENY
	end

	def self.clear!
		@config = nil
	end

	class Configuration
		attr_reader :roles
		attr_reader :max_inheritance_depth

		def initialize(options = {})
			@options = options
			@roles = {}

			if options[:max_inheritance_depth]
				@max_inheritance_depth = options[:max_inheritance_depth]
			else
				@max_inheritance_depth = 10
			end
		end

		def find_role!(name)
			role = self.roles[name]
			raise ::Roleback::MissingRole, "Role #{name} not found" unless role
			role
		end

		def can?(role_name, scope: ::Roleback::ANY, resource: ::Roleback::ANY, action: ::Roleback::ANY)
			role = self.find_role!(role_name)
			role.can?(scope: scope, resource: resource, action: action)
		end

		def construct!
			# go through all roles and find their parents
			@roles.each do |name, role|
				parents = role.parents
				next unless parents && !parents.empty?

				found_parents = []

				parents.each do |parent|
					found_parent = @roles[parent]
					raise ::Roleback::BadConfiguration, "Role #{parent} not found" unless found_parent

					found_parents << found_parent
					role.instance_variable_set(:@parents, found_parents)
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

			parents = options[:inherits_from]

			role = ::Roleback::Definitions::Role.new(name, parents: parents)
			role.instance_eval(&block) if block_given?

			roles[name] = role
			@config.instance_variable_set(:@roles, roles)

			role
		end

		def validate_options!(options)
			raise ::Roleback::BadConfiguration, "Invalid options" if options.keys.any? { |k| ![:inherits_from].include?(k) }
		end
	end
end
