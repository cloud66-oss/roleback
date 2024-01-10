RSpec.describe Roleback::UserExtension do
	let(:user_nil_class) { Class.new }
	let(:user_nil) { user_nil_class.new }
	let(:user) { Class.new { def roles; [:admin]; end }.new }

	before do
		user_nil_class.class_eval do
			def roles
				[]
			end
		end

		Roleback::UserExtension.extend!(user_nil_class)
		Roleback::UserExtension.extend!(user.class)
	end

	describe '#can?' do
		context 'when user has no roles' do
			it 'returns false' do
				expect(user_nil.can?(scope: nil, resource: nil, action: nil)).to be_falsey
			end
		end

		context 'when user has roles' do
			role = ::Roleback::Definitions::Role.new(:admin)
			resource = ::Roleback::Definitions::Resource.new(:users, role: role)
			scope = ::Roleback::Definitions::Scope.new(:admin, role: role)
			action = :show

			it 'returns true if any role can perform the action on the resource' do
				expect(user.can?(resource: resource, scope: scope, action: action)).to be_truthy
			end
		end
	end
end
