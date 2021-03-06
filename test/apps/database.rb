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

  class CreateSomeUsersToStartWith < ActiveRecord::Migration
    def change
      User.create! [
        {name: "Jon", email: "jon@example.com"},
        {name: "Hodor", email: "hodor@example.com"}
      ]
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
