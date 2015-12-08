# Minirails

> Run example rails app from single file

## Installation

```
$ gem install minirails
```

## Basic usage

Create a file `myapp.rb` with the following content

```ruby
# myapp.rb
define do |app|
  class ::MainController < ActionController::Base
    def index
      render text: "Hello"
    end
  end

  app.routes.draw do
    get "/", to: "main#index"
  end
end
```

and then run
```
$ minirails myapp.rb
```


## Advanced usage

### Multiple apps

You can run multiple applications from singe file

```ruby
# file: multiple.rb
# usage: $ minirails multiple.rb
define "one" do |app|
  app.routes.draw do
    get "/", to: proc {|*| [200, {}, "Hello".lines] }
  end
end

define "two" do |app|
  app.routes.draw do
    get "/", to: proc {|*| [200, {}, "World".lines] }
  end
end
```

### Database setup

You can also use full ActiveRecord capabilities.
The database (specified with `ENV["DATABASE_URL"]`) will be recreated (drop & create & migrate) on every run

```ruby
# file: database.rb
# usage: $ minirails database.rb
define "source" do |app|
  # Configuration
  ENV["DATABASE_URL"] = "postgresql://localhost/minirails_test"

  # Migrations
  class CreateUsers < ActiveRecord::Migration
    def change
      create_table :users do |t|
        t.string :name
        t.string :email
      end
    end
  end

  # Models
  class User < ActiveRecord::Base
  end

  # Controllers
  class UsersController < ActionController::Base
    def index
      render json: User.all
    end
  end

  # Routes
  app.routes.draw do
    resources :users
  end
end
```

## FAQ

- **How to speed up loading?**

  Run `$ minirails --fast` and then use `bin/minirails myapp.rb` instead


- **I'm getting "constant not found" errors!**

  You need to prefix your classes with `::` to put them in top level scope


## Contributing

1. Fork it ( https://github.com/teamon/minirails/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
