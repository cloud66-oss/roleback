module Roleback
	module Definitions
		class RuleBased
			attr_reader :role
			attr_reader :resource

			def initialize(role:, resource:, scope:)
				@role = role
				@resource = resource
				@scope = scope
			end

			def can(action)
				do_rule(role: @role, resource: @resource, scope: @scope, action: action, outcome: ::Roleback::ALLOW)
			end

			def cannot(action)
				do_rule(role: @role, resource: @resource, scope: @scope, action: action, outcome: ::Roleback::DENY)
			end

			def <=>(other)
				other.numerical_value <=> numerical_value
			end

			protected

			def do_rule(role:, resource:, scope:, action:, outcome:)
				rule = ::Roleback::Rule.new(
					role: role,
					resource: resource,
					scope: scope,
					action: action,
					outcome: outcome)

				role.add_rule(rule)
			end
		end
	end
end
