RSpec.describe Roleback::Definitions::Role do
	describe '#initialize' do
		it 'initializes a new Role object' do
			role = Roleback::Definitions::Role.new(:role_name)
			expect(role).to be_an_instance_of(Roleback::Definitions::Role)
		end

		it 'sets the parents to nil if no parent is provided' do
			role = Roleback::Definitions::Role.new(:role_name)
			expect(role.parents).to be_nil
		end

		it 'sets the parents to an array if a single parent is provided' do
			role = Roleback::Definitions::Role.new(:role_name, parents: :parent_role)
			expect(role.parents).to eq([:parent_role])
		end

		it 'sets the parents to the provided array if multiple parents are provided' do
			role = Roleback::Definitions::Role.new(:role_name, parents: [:parent1, :parent2])
			expect(role.parents).to eq([:parent1, :parent2])
		end

		it 'raises an error if parent is not a symbol or an array of symbols' do
			expect { Roleback::Definitions::Role.new(:role_name, parents: 123) }.to raise_error(Roleback::BadConfiguration)
		end
	end

	describe '#inherit' do
		it 'calls the private method do_inherit' do
			role = Roleback::Definitions::Role.new(:role_name)
			expect(role).to receive(:do_inherit)
			role.inherit
		end

		it 'supports single inheritance' do
			Roleback.define do |config|
				role :admin do
					can :administrate
				end

				role :user, inherits_from: :admin do
					can :view_charts
				end
			end

			expect(Roleback.configuration.roles[:admin].rules.length).to eq(1)
			expect(Roleback.configuration.roles[:user].rules.length).to eq(2)
		end

		it 'supports multiple inheritance' do
			Roleback.define do |config|
				role :admin do
					can :administrate
				end

				role :moderator, inherits_from: :admin do
					can :edit_posts
				end

				role :user, inherits_from: :moderator do
					can :view_posts
				end
			end

			expect(Roleback.configuration.roles[:admin].rules.length).to eq(1)
			expect(Roleback.configuration.roles[:moderator].rules.length).to eq(2)
			expect(Roleback.configuration.roles[:user].rules.length).to eq(3)
			expect(Roleback.configuration.roles[:user].rules['*:/*/administrate'].outcome).to eq(Roleback::ALLOW)
			expect(Roleback.configuration.roles[:user].rules['*:/*/edit_posts'].outcome).to eq(Roleback::ALLOW)
			expect(Roleback.configuration.roles[:user].rules['*:/*/view_posts'].outcome).to eq(Roleback::ALLOW)
		end

		it 'supports single inheritance with multiple parents' do
			Roleback.define do |config|
				role :admin do
					can :administrate
				end

				role :moderator do
					can :edit_posts
				end

				role :user, inherits_from: [:moderator, :admin] do
					can :view_posts
				end
			end

			expect(Roleback.configuration.roles[:admin].rules.length).to eq(1)
			expect(Roleback.configuration.roles[:moderator].rules.length).to eq(1)
			expect(Roleback.configuration.roles[:user].rules.length).to eq(3)
			expect(Roleback.configuration.roles[:user].rules['*:/*/administrate'].outcome).to eq(Roleback::ALLOW)
			expect(Roleback.configuration.roles[:user].rules['*:/*/edit_posts'].outcome).to eq(Roleback::ALLOW)
			expect(Roleback.configuration.roles[:user].rules['*:/*/view_posts'].outcome).to eq(Roleback::ALLOW)
		end

		it 'supports multiple inheritance with multiple parents' do
			Roleback.define do |config|
				role :admin do
					can :administrate
				end

				role :moderator do
					can :moderate
				end

				role :group_admin, inherits_from: :admin do
					can :group_administrate
				end

				role :user, inherits_from: [:moderator, :group_admin] do
					can :view_posts
				end
			end

			expect(Roleback.configuration.roles[:admin].rules.length).to eq(1)
			expect(Roleback.configuration.roles[:moderator].rules.length).to eq(1)
			expect(Roleback.configuration.roles[:group_admin].rules.length).to eq(2)
			expect(Roleback.configuration.roles[:user].rules.length).to eq(4)
			expect(Roleback.configuration.roles[:user].rules['*:/*/administrate'].outcome).to eq(Roleback::ALLOW)
			expect(Roleback.configuration.roles[:user].rules['*:/*/moderate'].outcome).to eq(Roleback::ALLOW)
			expect(Roleback.configuration.roles[:user].rules['*:/*/group_administrate'].outcome).to eq(Roleback::ALLOW)
			expect(Roleback.configuration.roles[:user].rules['*:/*/view_posts'].outcome).to eq(Roleback::ALLOW)
		end

		it 'allow shared ancestors' do
			Roleback.define do |config|
				role :admin do
					can :administrate
				end

				role :moderator, inherits_from: :admin do
					can :moderate
				end

				role :group_admin, inherits_from: :admin do
					can :group_administrate
				end

				role :user, inherits_from: [:moderator, :group_admin] do
					can :view_posts
				end
			end

			expect(Roleback.configuration.roles[:admin].rules.length).to eq(1)
			expect(Roleback.configuration.roles[:moderator].rules.length).to eq(2)
			expect(Roleback.configuration.roles[:group_admin].rules.length).to eq(2)
			expect(Roleback.configuration.roles[:user].rules.length).to eq(4)
			expect(Roleback.configuration.roles[:user].rules['*:/*/administrate'].outcome).to eq(Roleback::ALLOW)
			expect(Roleback.configuration.roles[:user].rules['*:/*/moderate'].outcome).to eq(Roleback::ALLOW)
			expect(Roleback.configuration.roles[:user].rules['*:/*/group_administrate'].outcome).to eq(Roleback::ALLOW)
			expect(Roleback.configuration.roles[:user].rules['*:/*/view_posts'].outcome).to eq(Roleback::ALLOW)
		end

		it 'rejects conflicting rules' do
			expect {
				Roleback.define do |config|
					role :admin do
						can :administrate
					end

					role :moderator, inherits_from: :admin do
						can :moderate
					end

					role :group_admin, inherits_from: :admin do
						cannot :administrate
					end

					role :user, inherits_from: [:moderator, :group_admin] do
						can :view_posts
					end
				end
			}.to raise_error(Roleback::BadConfiguration)
		end
	end
end
