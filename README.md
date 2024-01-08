# Roleback

Roleback is a simple DSL for writing static RBAC rules for your application. Roleback is not concerned with how you store or enforce your roles, it only cares about how you define them. Storing roles against a user class is easy enough, and there are plenty of gems out there to help you enforce them, like [Pundit](https://github.com/varvet/pundit) and [CanCanCan](https://github.com/CanCanCommunity/cancancan).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'roleback'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install roleback
```

## Usage

Using Roleback is simple. Define your roles in a ruby file, and then load them into your application. For example in Rails, you can create a file loaded during your application load, like `config/initializers/roles.rb`:

```ruby
# config/initializers/roles.rb
Roleback.define do
  role :admin do
    can :manage
  end
end
```

Roleback defines permissions on by roles. In the example above, we've defined a role called `admin` that can `manage` anything. Usually permissions are defined with three pieces of information: `scope`, `resource` and `action`.

`resource` is the object you want to check permissions against. `action` is the action you want to check permissions for. For example, you might want to check `read` action, on a blog `post`:

```ruby
# config/initializers/roles.rb
Roleback.define do
  role :admin do
    resource :post do
      can :read
    end
  end
end
```

`resource` however, always includes 7 more actions: `create`, `read`, `update`, `delete`, `list`, `edit` and `new` to make it easier to define permissions for common actions. You can change this behavior using the `only` and `except` options:

```ruby
# config/initializers/roles.rb
Roleback.define do
  role :admin do
    resource :post, only: [:read, :create, :update, :delete] do
      can :read
    end
  end
end
```

`scope` adds context to your permissions. For example, you might want to grant `read` on a `post` in the web, but not in other contexts (like an API):

```ruby
# config/initializers/roles.rb
Roleback.define do
  role :admin do
    scope :web do
      resource :post do
        can :read
      end
    end
  end
end
```

## Grant and Deny
Permissions are granted using `can` and denied using `cannot`:

```ruby
# config/initializers/roles.rb
Roleback.define do
  role :admin do
    scope :web do
      resource :post do
        can :read
        cannot :write
      end
    end
  end
end
```

By default, all `resource` default permissions (create, read, update, delete, list, edit and new) are granted (ie `can`).

## Inheritance
Roles can inherit from other roles:

```ruby
# config/initializers/roles.rb
Roleback.define do
  role :admin do
    can :manage
  end

  role :editor, parent: :admin do
    cannot :delete
  end
end
```

## Checking Permissions
Roleback doesn't care how you check permissions, but it does provide a simple API for doing so:

```ruby
Roleback.can?(:admin, resource: :post, action: :read) # => true
Roleback.can?(:editor, resource: :post, :delete) # => false
```

When checking for permissions, Rolebacks looks for the most explicit rule that matches the given parameters and works its way down to the least explicit. Deny rules always win over grant rules.


### `User` class
If you have a `User` class, Roleback will automatically, add a `can?` method to it:

```ruby
user = User.find(1)
user.can?(:admin, resource: :post, action: :read) # => true
user.can?(:editor, resource: :post, :delete) # => false
```

Your `User` class has to have a method called `roles` that returns an array of role names as symbols.

You can change the class to be extended from `User`, using `user_class` option in `define`:

```ruby
Roleback.define(user_class: Admin) do
  # ...
end
```

If you don't want to extend your `User` class, pass in `nil` as the `user_class` option:

```ruby
Roleback.define(user_class: nil) do
  # ...
end
```

## Contributing

Bug reports and pull requests are welcome on this GitHub repository. PRs are welcome and more likely to be accepted if they include tests.
