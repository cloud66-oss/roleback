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

			def inherit
				trace = {}
				@parents.each { |parent| trace[parent.to_s] = Set.new } if @parents && !@parents.empty?

				do_inherit(trace)
			end

			def to_s
				self.name.to_s
			end

			private

			# merge rules from a single parental line
			def do_inherit(trace)
				# for all parents of this role, inherit their rules

				return unless @parents

				@parents.each do |parent|
					trace[self.name] = Set.new if !trace.has_key?(self.name)

					if trace[self.name].include?(parent.to_s)
						raise ::Roleback::BadConfiguration, "Circular dependency detected: #{trace[self.name].to_a.join(' -> ')} -> #{parent.name}"
					end

					trace[self.name] << parent.to_s

					parent.send(:do_inherit, trace)

					# inherit parent's rules
					@rule_book.merge_without_overwrite(parent.rules)
				end
			end

		end
	end
end
