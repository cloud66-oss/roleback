module Roleback
	module Definitions
		class Role < Roleback::Definitions::RuleBased
			attr_reader :name
			attr_reader :parents

			def initialize(name, parents: nil)
				@name = name
				@rule_book = ::Roleback::RuleBook.new(self)
				@scopes = {}
				@resources = {}

				if parents
					if parents.is_a?(Symbol)
						@parents = [parents]
					elsif parents.is_a?(Array)
						# check for duplicates
						raise ::Roleback::BadConfiguration, "Duplicate parents found for role #{name}" if parents.uniq.length != parents.length

						@parents = parents
					else
						raise ::Roleback::BadConfiguration, "Parent must be a symbol or an array of symbols"
					end
				else
					@parents = nil
				end

				super(role: self, resource: ::Roleback::ANY, scope: ::Roleback::ANY)
			end

			def rules
				@rule_book
			end

			def keys
				@rule_book.rules.keys
			end

			def add_rule(rule)
				@rule_book.add(rule)
			end

			def resource(name, options = {}, &block)
				raise ::Roleback::BadConfiguration, "Resource #{name} already defined" if @resources[name]

				resource = ::Roleback::Definitions::Resource.new(name, role: self, options: options, &block)
				@resources[name] = resource
			end

			def scope(name, &block)
				raise ::Roleback::BadConfiguration, "Scope #{name} already defined" if @scopes[name]

				scope = ::Roleback::Definitions::Scope.new(name, role: self, &block)
				@scopes[name] = scope
			end

			def to_s
				self.name.to_s
			end

			def inherit
				return if @parents.nil?

				new_rules = do_inherit

				if new_rules.empty?
					# no rules to inherit
					return
				end

				# add the new rules to the rule book
				self.rules.clear_rules
				new_rules.each do |rule|
					self.rules.add(rule)
				end
			end

			private

			def do_inherit(rule_set = [], level = 0)
				# don't go too deep
				raise ::Roleback::BadConfiguration, "Circular dependency detected (#{level} out of maximum allowed of #{::Roleback.configuration.max_inheritance_depth})" if level > ::Roleback.configuration.max_inheritance_depth

				new_rules = rule_set + self.rules.to_a

				return new_rules if @parents.nil? || @parents.empty?

				@parents.each do |parent|
					parent_rules = parent.send(:do_inherit, rule_set, level + 1)
					new_rules = new_rules + parent_rules
				end

				return new_rules
			end

		end
	end
end
