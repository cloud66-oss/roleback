module Roleback
	class RuleBook
		attr_reader :rules

		def initialize
			@rules = {}
		end

		def add(rule)
			raise ::Roleback::BadConfiguration, "Rule #{rule.key} already defined" if @rules[rule.key]

			@rules[rule.key] = rule
		end

		def merge_without_overwrite(rule_book)
			rule_book.rules.each do |key, rule|
				add(rule) unless @rules[key]
			end
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
			match_book = self.class.new
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
				b.numerical_value <=> a.numerical_value
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
	end
end
