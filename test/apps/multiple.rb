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
