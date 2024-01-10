module Roleback
	class Rule
		attr_reader :role
		attr_reader :resource
		attr_reader :scope
		attr_reader :action
		attr_reader :outcome

		def initialize(role:, resource:, scope:, action:, outcome:)
			@role = role
			@resource = resource
			@scope = scope
			@action = action
			@outcome = outcome
		end

		def key
			"#{@scope.name}:/#{@resource.name}/#{@action}"
		end

		def to_s
			"#{key}->#{@outcome}"
		end

		def match(resource:, scope:, action:)
			if @resource.match(resource) && @scope.match(scope)
				if @action == ::Roleback.any || @action.to_s == action.to_s
					return self
				end
			end

			nil
		end

		# two rules are conflicting, when the have the same scope, resource and action, but different outcomes
		def conflicts_with?(rule)
			# if the rules are the same, they don't conflict
			return false if self == rule

			# if the scope, resource and action are the same, but the outcome is different, they conflict
			return true if @scope.name == rule.scope.name && @resource.name == rule.resource.name && @action == rule.action && @outcome.outcome != rule.outcome.outcome

			# otherwise, they don't conflict
			false
		end

		# calculate a numerical value for this rule to be used for sorting
		# the value is the sum of the following:
		# (scope_value * scope_weight) + (resource_value * resource_weight) * (outcome_value * outcome_weight)
		# scope_weight = 100
		# resource_weight = 10
		# outcome_weight = 1
		# scope_value = 1 if scope == ANY, 2 otherwise
		# resource_value = 1 if resource == ANY, 2 otherwise
		# outcome_value = 1 if outcome == ALLOW, 2 otherwise
		def numerical_value
			scope_value = @scope == ::Roleback::ANY ? 1 : 2
			resource_value = @resource == ::Roleback::ANY ? 1 : 2
			outcome_value = @outcome == ::Roleback::ALLOW ? 1 : 2

			(scope_value * 100) + (resource_value * 10) + (outcome_value * 1)
		end

	end
end
