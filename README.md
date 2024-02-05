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
    resource :post, only: [:read, :create, :update, :destroy] do
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

  role :editor, inherits_from: :admin do
    cannot :destroy
  end
end
```

Roles can also inherit from multiple roles:

```ruby
# config/initializers/roles.rb
Roleback.define do
  role :admin do
    can :manage
  end

  role :author do
    can :write
  end

  role :editor, inherits_from: [:admin, :author] do
    cannot :destroy
  end
end
```

While you don't need to define a parent role before the child role, circular dependencies are not allowed, within the same parental line. For example, if `:moderator` inherits from `:admin`, `:admin` cannot inherit from `:moderator`, directly or indirectly. However, when inheriting from multiple parents, circular dependencies are allowed, as long as they are not in the same parental line. For example, `:editor` can inherit from `:admin` and `:author`, and `:author` can inherit from `:editor`, as long as `:editor` does not inherit from `:author` directly or indirectly.

When it comes to consolidating the rules of inherited roles, Roleback allows repeated rules as long as they don't belong to the same role. For example, it is not allowed to define a rule twice, even with the same outcome:

```ruby
# config/initializers/roles.rb
Roleback.define do
  role :admin do
    can :manage
    can :manage # <- not allowed
  end
end
```

You can however, define the same rule in different roles, as long as they don't contradict each other:

```ruby
# config/initializers/roles.rb
Roleback.define do
  role :admin do
    can :manage
  end

  role :editor, inherits_from: :admin do
    can :manage
  end
end
```

```ruby
# config/initializers/roles.rb
Roleback.define do
  role :admin do
    can :manage
  end

  role :editor, inherits_from: :admin do
    cannot :manage # <- not allowed
  end
end
```

## Checking Permissions
Roleback doesn't care how you check permissions, but it does provide a simple API for doing so:

```ruby
Roleback.can?(:admin, resource: :post, action: :read) # => true
Roleback.can?(:editor, resource: :post, action: :destroy) # => false
```

After the definition of roles is finished (`Roleback.define`), all each role, ends up with the collection of all rules it has plus all the rules it has inherited from other roles. These rules are used to check for permissions. When the `can?` method is called with `scope`, `resource` and `action`, `can?` will return the outcome of the most specific rule that matches the given `scope`, `resource` and `action`. If no rule matches, `can?` will return `false`. If you have both `can` and `cannot` rules for a check, `cannot` will take precedence (deny over grant).

### `User` class
If you have a `User` class, Roleback will automatically, add a `can?` method to it:

```ruby
user = User.find(1) # user.roles => [:admin]
user.can?(resource: :post, action: :read) # => true
user.can?(resource: :post, action: :destroy) # => false
```

Your `User` class has to have a method called `roles` that returns an array of role names as symbols.

The `User` class returns an array of roles, then Roleback will check each role for a match and will return `true` (grant) when the first role matches. If no role matches, `can?` will return `false`. This is an important point to remember when using class extension, which basically means if you grant the user multiple rules, it will return `true` if any of the rules match, even you have rules that deny access to the same resource and action.

You can change the class to be extended from `User`, using `user_class` option in `define`:

```ruby
Roleback.define user_class: Admin do
  # ...
end
```

If you don't want to extend your `User` class, pass in `nil` as the `user_class` option:

```ruby
Roleback.define user_class: nil do
  # ...
end
```

## Recommendations

Even though Roleback doesn't impose any opinions on how define your rules (sacrilegious in Rails world, I know), here are some recommendations that might help using it with more ease:

1. Although Roleback, support deny permissions (`cannot`), I recommend against using those and always define your rules with grant permissions (`can`). This will make it easier to reason about your rules and will make it easier to debug them.
2. Either map your roles to actual organizational roles (marketing, support, etc), or define them based on their access context (commenter, editor, etc). Don't mix the two. Use multiple inheritance when defining the roles based on access context and use single inheritance when defining them based on organizational roles.
3. Define your roles in a single file, and load them during application load. (`config/initializers/roles.rb` in Rails is a good place).

## Contributing

Bug reports and pull requests are welcome on this GitHub repository. PRs are welcome and more likely to be accepted if they include tests.
