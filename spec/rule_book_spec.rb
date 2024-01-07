RSpec.describe Roleback::RuleBook do
	describe '#add' do
		it 'adds a rule' do
			rule_book = described_class.new
			rule1 = double('rule', key: :foo)
			rule_book.add(rule1)
			expect(rule_book.rules).to eq({ foo: rule1 })
		end

		it 'raises an error if a rule with the same key already exists' do
			rule_book = described_class.new
			rule1 = double('rule', key: :foo)
			rule_book.add(rule1)
			expect { rule_book.add(rule1) }.to raise_error(Roleback::BadConfiguration)
		end
	end

	describe '#merge_without_overwrite' do
		it 'merges two rule books without overwriting' do
			rule_book = described_class.new
			rule1 = double('rule', key: :foo)
			rule_book.add(rule1)

			other_rule_book = described_class.new
			other_rule = double('rule', key: :bar)
			other_rule_book.add(other_rule)

			rule_book.merge_without_overwrite(other_rule_book)

			expect(rule_book.rules).to eq({ foo: rule1, bar: other_rule })
		end

		it 'does not overwrite existing rules' do
			rule_book = described_class.new
			rule1 = double('rule', key: :foo)
			rule_book.add(rule1)

			other_rule_book = described_class.new
			other_rule = double('rule', key: :foo)
			other_rule_book.add(other_rule)

			rule_book.merge_without_overwrite(other_rule_book)

			expect(rule_book.rules).to eq({ foo: rule1 })
		end
	end

	describe '#length' do
		it 'returns the number of rules' do
			rule_book = described_class.new
			rule1 = double('rule', key: :foo)
			rule_book.add(rule1)
			expect(rule_book.length).to eq(1)
		end
	end

	describe '#[]' do
		it 'returns the rule with the given key' do
			rule_book = described_class.new
			rule1 = double('rule', key: :foo)
			rule_book.add(rule1)
			expect(rule_book[:foo]).to eq(rule1)
		end
	end

	describe '#keys' do
		it 'returns the keys of the rules' do
			rule_book = described_class.new
			rule1 = double('rule', key: :foo)
			rule_book.add(rule1)
			expect(rule_book.keys).to eq([:foo])
		end
	end

	describe '#match' do
		it 'returns all rules that matches the given resource, scope and action' do
			rule_book = ::Roleback::RuleBook.new

			role = ::Roleback::Definitions::Role.new(:admin)
			resource = ::Roleback::Definitions::Resource.new(:users, role: role)
			scope1 = ::Roleback::Definitions::Scope.new(:admin, role: role)
			scope2 = ::Roleback::Definitions::Scope.new(:public, role: role)

			rule1 = ::Roleback::Rule.new(role: role, resource: resource, scope: scope1, action: :show, outcome: ::Roleback::ALLOW)
			rule_book.add(rule1)

			rule2 = ::Roleback::Rule.new(role: role, resource: resource, scope: scope1, action: :index, outcome: ::Roleback::DENY)
			rule_book.add(rule2)

			rule3 = ::Roleback::Rule.new(role: role, resource: resource, scope: scope2, action: :show, outcome: ::Roleback::ALLOW)
			rule_book.add(rule3)

			expect{
				rule_book.match_all(resource: ::Roleback::ANY, scope: ::Roleback::ANY, action: :show)
			}.to raise_error(::Roleback::BadMatch)

			expect{
				rule_book.match_all(resource: resource, scope: ::Roleback::ANY, action: :show)
			}.to raise_error(::Roleback::BadMatch)

			expect{
				rule_book.match_all(resource: ::Roleback::ANY, scope: scope1, action: :show)
			}.to raise_error(::Roleback::BadMatch)

			expect(rule_book.match_all(resource: resource, scope: scope1, action: :show)).to eq([rule1])
			expect(rule_book.match_all(resource: resource, scope: scope1, action: :index)).to eq([rule2])
		end
	end

	describe '#can?' do
		it 'returns true if the user can perform the action on the resource' do
			rule_book = ::Roleback::RuleBook.new

			role = ::Roleback::Definitions::Role.new(:admin)
			resource = ::Roleback::Definitions::Resource.new(:users, role: role)
			scope1 = ::Roleback::Definitions::Scope.new(:admin, role: role)
			scope2 = ::Roleback::Definitions::Scope.new(:public, role: role)

			rule1 = ::Roleback::Rule.new(role: role, resource: resource, scope: scope1, action: :show, outcome: ::Roleback::ALLOW)
			rule_book.add(rule1)

			rule2 = ::Roleback::Rule.new(role: role, resource: resource, scope: scope1, action: :index, outcome: ::Roleback::DENY)
			rule_book.add(rule2)

			rule3 = ::Roleback::Rule.new(role: role, resource: resource, scope: scope2, action: :show, outcome: ::Roleback::ALLOW)
			rule_book.add(rule3)

			expect(rule_book.can?(resource: resource, scope: scope1, action: :show)).to eq(true)
			expect(rule_book.can?(resource: resource, scope: scope1, action: :index)).to eq(false)
			expect(rule_book.can?(resource: resource, scope: scope2, action: :show)).to eq(true)
			expect(rule_book.can?(resource: resource, scope: scope2, action: :index)).to eq(false)
			expect(rule_book.can?(resource: resource, scope: scope2, action: :create)).to eq(false)
		end

		it 'returns the explict outcome over a any outcome' do
			rule_book = ::Roleback::RuleBook.new

			role = ::Roleback::Definitions::Role.new(:admin)
			resource = ::Roleback::Definitions::Resource.new(:users, role: role)
			scope = ::Roleback::Definitions::Scope.new(:admin, role: role)

			# explict deny
			rule1 = ::Roleback::Rule.new(role: role, resource: resource, scope: scope, action: :show, outcome: ::Roleback::DENY)

			# any allow
			rule2 = ::Roleback::Rule.new(role: role, resource: ::Roleback::ANY, scope: ::Roleback::ANY, action: :show, outcome: ::Roleback::ALLOW)

			rule_book.add(rule1)
			rule_book.add(rule2)

			expect(rule_book.can?(resource: resource, scope: scope, action: :show)).to eq(false)
		end

		it 'returns the explict allow over a any deny outcome' do
			rule_book = ::Roleback::RuleBook.new

			role = ::Roleback::Definitions::Role.new(:admin)
			resource = ::Roleback::Definitions::Resource.new(:users, role: role)
			scope = ::Roleback::Definitions::Scope.new(:admin, role: role)

			# explict allow
			rule1 = ::Roleback::Rule.new(role: role, resource: resource, scope: scope, action: :show, outcome: ::Roleback::ALLOW)

			# any deny
			rule2 = ::Roleback::Rule.new(role: role, resource: ::Roleback::ANY, scope: ::Roleback::ANY, action: :show, outcome: ::Roleback::DENY)

			rule_book.add(rule1)
			rule_book.add(rule2)

			# explict question
			expect(rule_book.can?(resource: resource, scope: scope, action: :show)).to eq(true)

			# any question
			expect {
				rule_book.can?(resource: ::Roleback::ANY, scope: ::Roleback::ANY, action: :show)
			}.to raise_error(::Roleback::BadMatch)
		end
	end

	describe '#sort' do
		it 'sorts rules based on the rules numerical values and outcome' do
			Roleback.configure do |config|
				role :admin do
					resource :users do
						can :work
					end

					can :see

					scope :api do
						resource :users do
							cannot :work
							can :rest
						end
					end
				end
			end

			rules = Roleback.configuration.roles[:admin].rules
			sorted_rules = rules.sort

			# make sure rules and sorted_rules are not the same object
			expect(rules).not_to be(sorted_rules)

			expect(rules.length).to eq(18)

			# make sure the rules are sorted correctly based on the following list
			expect(sorted_rules[0].to_s).to eq('api:/users/work->deny')
			expect(sorted_rules[1].to_s).to eq('api:/users/rest->allow')
			expect(sorted_rules[2].to_s).to eq('api:/users/create->allow')
			expect(sorted_rules[3].to_s).to eq('api:/users/show->allow')
			expect(sorted_rules[4].to_s).to eq('api:/users/update->allow')
			expect(sorted_rules[5].to_s).to eq('api:/users/delete->allow')
			expect(sorted_rules[6].to_s).to eq('api:/users/index->allow')
			expect(sorted_rules[7].to_s).to eq('api:/users/new->allow')
			expect(sorted_rules[8].to_s).to eq('api:/users/edit->allow')
			expect(sorted_rules[9].to_s).to eq('*:/users/create->allow')
			expect(sorted_rules[10].to_s).to eq('*:/users/show->allow')
			expect(sorted_rules[11].to_s).to eq('*:/users/update->allow')
			expect(sorted_rules[12].to_s).to eq('*:/users/delete->allow')
			expect(sorted_rules[13].to_s).to eq('*:/users/index->allow')
			expect(sorted_rules[14].to_s).to eq('*:/users/new->allow')
			expect(sorted_rules[15].to_s).to eq('*:/users/edit->allow')
			expect(sorted_rules[16].to_s).to eq('*:/users/work->allow')
			expect(sorted_rules[17].to_s).to eq('*:/*/see->allow')
		end
	end
end
