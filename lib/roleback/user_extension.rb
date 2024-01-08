module Roleback
	class UserExtension
		def self.extend!(user_class)
			user_instance = user_class.new
			unless user_instance.respond_to?(:roles) && user_instance.method(:roles).arity == 0
				raise ::Roleback::InvalidOrMisconfiguredUserClass, "User class #{user_class.name} should have a method call roles that returns an array of role names"
			end

			if user_class.instance_methods.include?(:can?)
				raise ::Roleback::InvalidOrMisconfiguredUserClass, "User class #{user_class.name} already has a method called can?"
			end

			user_class.class_eval do
				def can?(resource: Roleback.any, scope: Roleback.any, action: Roleback.any)
					# get all user roles
					roles = self.roles
					return false if roles.empty?

					if !roles.is_a?(Array)
						raise ::Roleback::InvalidOrMisconfiguredUserClass, "User class #{self.class}#roles should return an array of role names"
					end

					roles.each do |role|
						return true if ::Roleback.configuration.can?(role, resource: resource, scope: scope, action: action)
					end

					# no role can perform the action on the resource
					false
				end
			end
		end
	end
end
