module Roleback
	module Definitions
		class Role < Roleback::Definitions::RuleBased
			attr_reader :name
			attr_reader :parent

			def initialize(name, parent: nil)
				@name = name
				@rule_book = ::Roleback::RuleBook.new
				@scopes = {}
				@resources = {}
				@parent = parent

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
				do_inherit
			end

			private

			def do_inherit(trace = Set.new)
				# does this role have a parent, if so, call inherit on it
				parent = @parent
				return unless parent

				raise ::Roleback::BadConfiguration, "Circular dependency detected: #{trace.to_a.map(&:name).join(' -> ')} -> #{parent.name}" if trace.include?(parent)

				trace << parent

				parent.send(:do_inherit, trace)

				# inherit parent's rules
				@rule_book.merge_without_overwrite(parent.rules)
			end

		end
	end
end
