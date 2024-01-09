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

			# Experiment
			# h is a hash of node name -> [parent1, parent2, ...]
			def build_graph(h = {}, level = 0)
				# don't go too deep
				if level > 16
					puts "		Too deep"
					return h
				end

				add_parents(h)

				if @parents
					@parents.each do |parent|
						h = parent.send(:build_graph, h, level + 1)
					end
				end

				h
			end

			def has_circular_dependency?(h)
				# find the root
				root = find_root(h)

				# if there is no root, there is no circular dependency
				return false unless root

				# if the root has no parents, there is no circular dependency
				return false unless h[root]

				# if the root has parents, there is a circular dependency
				true
			end


			def add_parents(h)
				h[self.name] = nil unless h.has_key?(self.name)

				if @parents
					unique_parent_names = @parents.map(&:to_s).uniq
					if h[self.name]
						h[self.name] = (h[self.name] + unique_parent_names).uniq
					else
						h[self.name] = unique_parent_names
					end
				end
			end

			# find the root of the tree
			def find_root(h)
				h.each do |k, v|
					return k if v.nil?
				end

				nil
			end

			def delete_root(h)
				root = find_root(h)
				h.delete(root)

				h.each do |k, v|
					if v
						v.delete(root)
					end
				end

				h
			end

		end
	end
end
