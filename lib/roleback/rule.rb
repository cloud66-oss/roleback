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
				if @action == ::Roleback::ANY || @action == action
					return self
				end
			end

			nil
		end

		# calculate a numerical value for this rule to be used for sorting
		# the value is the sum of the following:
		# (scope_value * scope_weight) + (resource_value * resource_weight) * (outcome_value * outcome_weight)
		# scope_weight = 100
		# resource_weight = 10
		# outcome_weight = 1
		# scope_value = 0 if scope == ANY, 1 otherwise
		# resource_value = 0 if resource == ANY, 1 otherwise
		# outcome_value = 0 if outcome == ALLOW, 1 otherwise
		def numerical_value
			scope_value = @scope == ::Roleback::ANY ? 0 : 1
			resource_value = @resource == ::Roleback::ANY ? 0 : 1
			outcome_value = @outcome == ::Roleback::ALLOW ? 0 : 1

			(scope_value * 100) + (resource_value * 10) + (outcome_value * 1)
		end

	end
end
