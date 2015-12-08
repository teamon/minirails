define "hello" do |app|
  class ::MainController < ActionController::Base
    def index
      render text: "Hello"
    end
  end

  app.routes.draw do
    get "/", to: "main#index"
  end
end
