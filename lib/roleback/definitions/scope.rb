module Roleback
	module Definitions
		class Scope < ::Roleback::Definitions::RuleBased
			attr_reader :name

			def initialize(name, role:, options: {}, &block)
				@name = name
				@role = role
				@options = options

				super(role: role, scope: self, resource: ::Roleback::ANY)

				instance_eval(&block) if block_given?
			end

			def resource(name, options = {}, &block)
				::Roleback::Definitions::Resource.new(name, role: @role, scope: self, options: options, &block)
			end

			def match(scope)
				to_check = scope.is_a?(::Roleback::Definitions::Scope) ? scope.name.to_s : scope.to_s
				@name.to_s == scope.name.to_s || @name == ::Roleback.any || scope == ::Roleback.any
			end

			def ==(other)
				return false unless other.respond_to?(:name)

				other.name == name
			end

		end
	end
end
