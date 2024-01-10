module Roleback
	class RuleBook
		attr_reader :rules

		def initialize(role)
			@rules = {}
			@role = role
		end

		def add(rule)
			raise ::Roleback::BadConfiguration, "Adding a rule with no role" unless rule.role

			if @rules[rule.key]
				if @rules[rule.key].outcome.outcome == rule.outcome.outcome
					# don't allow it if they share a rulebook
					if @role.name == rule.role.name
						raise ::Roleback::BadConfiguration, "Rule #{rule.key} already defined"
					else
						# this duplicate is through inheritance, so we can safely ignore it
						return
					end
				else
					raise ::Roleback::BadConfiguration, "Rule #{rule.key} already defined with a different outcome (conflicting rules)"
				end
			end

			# detect conflicting rules
			@rules.each do |key, existing_rule|
				if existing_rule.conflicts_with?(rule)
					raise ::Roleback::BadConfiguration, "Rule #{rule.key} conflicts with #{existing_rule.key}"
				end
			end

			@rules[rule.key] = rule
		end

		def clear_rules
			@rules = {}
		end

		def length
			@rules.length
		end

		def [](key)
			@rules[key]
		end

		def keys
			@rules.keys
		end

		def match_all(resource:, scope:, action:)
			result = []
			@rules.each do |key, rule|
				result << rule if rule.match(resource: resource, scope: scope, action: action)
			end

			result
		end

		def can?(resource:, scope:, action:)
			# get all rules that matches the given resource, scope and action
			rules = match_all(resource: resource, scope: scope, action: action)

			# if there are no rules, return false
			return false if rules.empty?

			# create a rule book with the matching rules
			match_book = self.class.new(@role)
			rules.each do |rule|
				match_book.add(rule)
			end

			# sort the rules
			sorted_rules = self.class.sort(match_book.rules)

			# iterate over the sorted rules and find the first rule that matches
			sorted_rules.each do |rule|
				if rule.match(resource: resource, scope: scope, action: action)
					return rule.outcome.allowed?
				end
			end

			# if no rule matches, return false
			return false
		end

		# sorts the rules, based on the rules' numerical value
		def self.sort(rules)
			# rules should be a hash
			raise ::ArgumentError, "rules should be a hash but it is a #{rules.class}" unless rules.is_a?(Hash)

			# rules is a hash, so we need to convert it to an array
			rules = rules.values

			# sort the rules
			rules.sort! do |a, b|
				an = a.numerical_value
				bn = b.numerical_value

				# if the numerical values are the same, sort by key, otherwise sort by numerical value
				if an == bn
					a.key <=> b.key
				else
					bn <=> an
				end
			end
		end

		def sort!
			@rules = self.class.sort(@rules)
		end

		def sort
			self.class.sort(@rules)
		end

		def to_s
			@rules.values.map(&:to_s).join("\n")
		end

		def to_a
			@rules.values
		end
	end
end
