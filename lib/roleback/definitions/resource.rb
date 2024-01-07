module Roleback
	module Definitions
		class Resource < ::Roleback::Definitions::RuleBased
			attr_reader :name

			DEFAULT_ACTION_PATH = [:create, :show, :update, :delete, :index, :new, :edit]

			def initialize(name, role:, scope: ::Roleback::ANY, options: {}, &block)
				@name = name
				@role = role
				@scope = scope
				@options = options

				super(role: role, resource: self, scope: scope)

				validate_options!

				# create rules for each action
				selected_actions.each do |action|
					do_rule(role: @role, resource: self, scope: @scope, action: action, outcome: ::Roleback::ALLOW)
				end

				instance_eval(&block) if block_given?
			end

			def match(resource)
				@name == resource.name || @name == ::Roleback::ANY || resource == ::Roleback::ANY
			end

			def ==(other)
				return false unless other.respond_to?(:name)

				other.name == name
			end

			private

			def validate_options!
				if @options[:only] && @options[:except]
					raise ::Roleback::BadConfiguration, "You can't specify both :only and :except options"
				end

				if @options[:only] && !@options[:only].is_a?(Array)
					raise ::Roleback::BadConfiguration, "The :only option must be an array"
				end

				if @options[:except] && !@options[:except].is_a?(Array)
					raise ::Roleback::BadConfiguration, "The :except option must be an array"
				end

				if @options.keys.any? { |k| ![:only, :except].include?(k) }
					raise ::Roleback::BadConfiguration, "Invalid options"
				end
			end

			def selected_actions
				if @options[:only]
					return @options[:only]
				elsif @options[:except]
					return DEFAULT_ACTION_PATH - @options[:except]
				else
					return DEFAULT_ACTION_PATH
				end
			end
		end
	end
end
