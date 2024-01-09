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
				combined_rules = rules.to_a

				if @parents && !@parents.empty?
					@parents.each do |parent|
						parent_rules = do_inherit([], parent, Set.new)
						combined_rules += parent_rules
					end
				end

				# replace the rules with the combined rules
				unless combined_rules.empty?
					@rule_book.clear_rules
					combined_rules.each do |rule|
						@rule_book.add(rule)
					end
				end
			end

			private

			# merge rules from a single parental line
			def do_inherit(combined_rules, lineage, trace)
				return lineage.rules.to_a unless lineage.parents

				# add it to the trace
				trace.add(lineage.name.to_s)

				# inherit parent's rules
				combined_rules += lineage.rules.to_a

				# iterate over the parents
				lineage.parents.each do |parent|
					# check for circular references
					raise ::Roleback::BadConfiguration, "Circular dependency detected in role #{self.name.to_s}: #{trace.to_a.join(' -> ')}" if trace.include?(parent.to_s)

					# inherit the parent's rules
					combined_rules += do_inherit(combined_rules, parent, trace)
				end

				combined_rules
			end

		end
	end
end
