RSpec.describe Roleback::UserExtension do
	let(:user_class) { Class.new }
	let(:user) { user_class.new }

	before do
		user_class.class_eval do
			def roles
				[]
			end
		end

		Roleback::UserExtension.extend!(user_class)
	end

	describe '#can?' do
		context 'when user has no roles' do
			it 'returns false' do
				expect(user.can?(scope: nil, resource: nil, action: nil)).to be_falsey
			end
		end

		context 'when user has roles' do
			let(:role) { double('Role') }
			let(:resource) { double('Resource') }
			let(:scope) { double('Scope') }
			let(:action) { double('Action') }

			before do
				allow(user).to receive(:roles).and_return([role])
				allow(Roleback.configuration).to receive(:find_role!).with(role).and_return(role)
				allow(role).to receive(:can?).with(resource: resource, scope: scope, action: action).and_return(true)
			end

			it 'returns true if any role can perform the action on the resource' do
				expect(user.can?(resource: resource, scope: scope, action: action)).to be_truthy
			end

			it 'returns false if no role can perform the action on the resource' do
				allow(role).to receive(:can?).with(resource: resource, scope: scope, action: action).and_return(false)
				expect(user.can?(resource: resource, scope: scope, action: action)).to be_falsey
			end
		end
	end
end
