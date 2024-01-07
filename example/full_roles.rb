Roleback.configure do |config|
	role :support do
		can :view_charts
		can :edit_tag
		can :delete_tag

		cannot :edit_account
	end

	role :support_senior, inherits: :support do
		resource :tags do
			can :list
		end

		scope :api do
			resource :charts, only: [:view]
		end

		resource :charts, only: [:view]
		resource :reports, except: [:create, :run, :edit, :delete]
	end

	user.can? :view_charts
	user.can? :list, on: :tags, scope: :api
	user.can? :tags, :list
	user.can? :view_charts, scope: :api
	user.roles # => [:support, :support_senior]
	user.permissions # => [:view_charts, :tags_list]
	user.permissions_for(:tags) # => [:list]
	roles # => [:support, :support_senior]
	permissions # => [:view_charts, :tags_list]
	permissions_for(:tags) # => [:list]

	# /charts/view -> allow
	# /charts/* -> deny
	# api:/charts/view
end
