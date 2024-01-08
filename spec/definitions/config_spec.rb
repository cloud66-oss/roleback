RSpec.describe Roleback::Configuration do
	before do
		Roleback.clear!
	end

	it "fails without configuration" do
		expect {
			Roleback.configuration
		}.to raise_error(Roleback::NotConfiguredError)
	end

    it "has a configuration" do
        Roleback.define do |config|
        end
    end

	it "has a role within configuration" do
		Roleback.define do |config|
			role :admin do
			end

			role :user do
			end
		end

		expect(Roleback.configuration.roles).to have_key(:admin)
		expect(Roleback.configuration.roles).to have_key(:user)
	end

	it "stops duplicate roles" do
		expect {
			Roleback.define do |config|
				role :admin do
				end

				role :admin do
				end
			end
		}.to raise_error(Roleback::BadConfiguration)
	end

	it "has a role with permissions" do
		Roleback.define do |config|
			role :admin do
				can :view_charts
				can :edit_tag
				can :delete_tag

				cannot :edit_account
			end
		end

		expect(Roleback.configuration.roles[:admin].rules.length).to eq(4)
	end

	it "has a role with permissions and resources" do
		Roleback.define do |config|
			role :admin do
				can :see_me
				can :purge_values
				can :manage_users

				cannot :forward_emails

				resource :charts do
					can :view
				end
			end
		end

		expect(Roleback.configuration.roles[:admin].rules.length).to eq(12)
	end

	it "adds default rules for resources" do
		Roleback.define do |config|
			role :admin do
				resource :charts
			end
		end

		expect(Roleback.configuration.roles[:admin].rules.length).to eq(7)
	end

	it "blocks duplicate resources" do
		expect {
			Roleback.define do |config|
				role :admin do
					resource :charts
					resource :charts
				end
			end
		}.to raise_error(Roleback::BadConfiguration)
	end

	it "blocks duplicate rules by key" do
		expect {
			Roleback.define do |config|
				role :admin do
					can :see_me
					can :see_me
				end
			end
		}.to raise_error(Roleback::BadConfiguration)
	end

	it "adds the right rule" do
		Roleback.define do |config|
			role :admin do
				can :see_me
				cannot :fool_me
			end
		end

		expect(Roleback.configuration.roles[:admin].rules.length).to eq(2)
		expect(Roleback.configuration.roles[:admin].rules['*:/*/see_me']).to be_a(Roleback::Rule)
		expect(Roleback.configuration.roles[:admin].rules['*:/*/see_me'].outcome).to eq(Roleback::ALLOW)
		expect(Roleback.configuration.roles[:admin].rules['*:/*/fool_me']).to be_a(Roleback::Rule)
		expect(Roleback.configuration.roles[:admin].rules['*:/*/fool_me'].outcome).to eq(Roleback::DENY)
	end

	it "has a role with scopes" do
		Roleback.define do |config|
			role :admin do
				can :see_me
				cannot :fool_me

				scope :api
			end
		end

		expect(Roleback.configuration.roles[:admin].rules.length).to eq(2)
	end

	it "blocks duplicate scopes" do
		expect {
			Roleback.define do |config|
				role :admin do
					scope :api
					scope :api
				end
			end
		}.to raise_error(Roleback::BadConfiguration)
	end

	it "adds the right number of rules for resources" do
		Roleback.define do |config|
			role :admin do
				resource :charts, except: [:index]
			end
		end

		expect(Roleback.configuration.roles[:admin].rules.length).to eq(6)
	end

	it "only accpets valid resource options" do
		expect {
			Roleback.define do |config|
				role :admin do
					resource :charts, except: [:index], invalid: [:index]
				end
			end
		}.to raise_error(Roleback::BadConfiguration)

		expect {
			Roleback.define do |config|
				role :admin do
					resource :charts, except: [:foo]
				end
			end
		}.not_to raise_error
	end

	it "has resources in scope" do
		Roleback.define do |config|
			role :admin do
				scope :api do
					resource :charts
				end
			end
		end

		expect(Roleback.configuration.roles[:admin].rules.length).to eq(7)
		expect(Roleback.configuration.roles[:admin].rules.keys.all? { |k| k.start_with?('api:') }).to be_truthy
	end

	it "cannot have scope in a resource" do
		expect {
			Roleback.define do |config|
				role :admin do
					resource :charts do
						scope :api
					end
				end
			end
		}.to raise_error(::NoMethodError)
	end

	it "cannot have nested resources" do
		expect {
			Roleback.define do |config|
				role :admin do
					resource :charts do
						resource :charts
					end
				end
			end
		}.to raise_error(::ArgumentError)
	end

	it "cannot have nested scopes" do
		expect {
			Roleback.define do |config|
				role :admin do
					scope :api do
						scope :api
					end
				end
			end
		}.to raise_error(::NoMethodError)
	end

	it "cannot have nested roles" do
		expect {
			Roleback.define do |config|
				role :admin do
					role :admin
				end
			end
		}.to raise_error(::ArgumentError)
	end

	it "rejects bad role options" do
		expect {
			Roleback.define do |config|
				role :admin, foo: :bar
			end
		}.to raise_error(Roleback::BadConfiguration)
	end

	it "rejects non-existent parent roles" do
		expect {
			Roleback.define do |config|
				role :admin, inherits_from: :foo
			end
		}.to raise_error(Roleback::BadConfiguration)
	end


	it "can inherit roles" do
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

	it "rule inheritence works" do
		Roleback.define do |config|
			role :admin do
				can :administrate
			end

			role :user, inherits_from: :admin do
				can :view_charts
				cannot :have_fun
			end
		end

		expect(Roleback.configuration.roles[:admin].rules.length).to eq(1)
		expect(Roleback.configuration.roles[:user].rules.length).to eq(3)
		expect(Roleback.configuration.roles[:user].rules['*:/*/administrate'].outcome).to eq(Roleback::ALLOW)
		expect(Roleback.configuration.roles[:user].rules['*:/*/view_charts'].outcome).to eq(Roleback::ALLOW)
		expect(Roleback.configuration.roles[:user].rules['*:/*/have_fun'].outcome).to eq(Roleback::DENY)
	end

	it "can inherit roles with multiple parents" do
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

	it "reject circular dependencies" do
		expect {
			Roleback.define do |config|
				role :admin, inherits_from: :user
				role :moderator, inherits_from: :admin
				role :user, inherits_from: :moderator
			end
		}.to raise_error(Roleback::BadConfiguration)
	end

end
