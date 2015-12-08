define "rails" do |app|
  app.routes.draw do
    get "/", to: proc {|*| [200, {}, "Hello from Rails".lines] }
  end
end

define "worker", type: :blank, initialize: "rails" do
  loop do
    Rails.logger.debug "Hello from worker with Rails env"
    sleep 1
  end
end
