define "rails" do |app|
  app.routes.draw do
    get "/", to: proc {|*| [200, {}, "Hello from Rails".lines] }
  end
end

define "rack", type: :rack do
  proc {|*| [200, {}, "Hello from Rack".lines] }
end

define "worker", type: :blank do
  loop do
    $stderr.puts "Hello from worker"
    sleep 1
  end
end
