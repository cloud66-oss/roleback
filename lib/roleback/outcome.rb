module Roleback
	class OutcomeBase
		attr_reader :outcome

		def initialize(outcome)
			@outcome = outcome
		end

		def allowed?
			@outcome == :allow
		end

		def denied?
			@outcome == :deny
		end

		def to_s
			@outcome.to_s
		end

		def ==(other)
			return false unless other.respond_to?(:outcome)

			other.outcome == outcome
		end
	end

	class Allow < OutcomeBase
		def initialize
			super(:allow)
		end
	end

	class Deny < OutcomeBase
		def initialize
			super(:deny)
		end
	end

	class Any
		def name
			:'*'
		end

		def ==(other)
			return true if other.is_a?(Any)
			return false unless other.respond_to?(:name)

			other.name.to_s == name.to_s
		end

		def match(scope)
			true
		end
	end

	ANY = Any.new

	ALLOW = Allow.new
	DENY = Deny.new
end
