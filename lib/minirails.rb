require "minirails/version"

module Minirails
  def self.run(argv)
    builder = Builder.new(argv[0])

    if argv[1]
      builder.start(argv[1].to_i)
    else
      builder.spawn
    end
  end

  class Builder < Struct.new(:specfile)
    # DSL API
    def define(name = nil, &block)
      apps << App.new(name, block)
    end

    # internals
    def start(num)
      boot

      $stderr.puts "--> Loading rails"
      require "action_controller"
      require "rails"
      require "active_record/railtie"
      $stderr.puts "--> Loading app"

      # require "pry"; binding.pry

      Rack::Handler::WEBrick.run(apps[num].endpoint, :Port => ENV["PORT"])
    end

    def spawn
      boot

      require "foreman/engine/cli"

      engine = Foreman::Engine::CLI.new
      apps.each.with_index do |app, index|
        engine.register(
          app.name || "web-#{index}",
          "#{File.expand_path($0)} #{File.expand_path(specfile)} #{index}",
          cwd: Dir.pwd
        )
      end

      engine.start
    end

    protected

    def apps
      @apps ||= []
    end

    def boot
      eval File.read(specfile)
    end
  end

  class App < Struct.new(:name, :block)
    def build
      # basic rails app bootstrap
      app = Class.new(Rails::Application) do
        config.eager_load = false
        config.secret_key_base = SecureRandom.hex
        config.logger = Logger.new(STDERR)
      end

      # ActiveRecord specific configuration
      if app.config.respond_to?(:active_record)
        app.config.active_record.dump_schema_after_migration = false
      end

      # initialize app
      app.initialize!

      # execute 'define' block
      block.call(app)

      # ActiveRecord post functions
      if app.config.respond_to?(:active_record)
        # load rake tasks
        app.load_tasks

        # create and migrate database
        Rake::Task["db:drop"].invoke
        Rake::Task["db:create"].invoke
        ActiveRecord::Migration.descendants.each {|e| e.migrate :up }
      end

      # and finally return app object
      app
    end

    def endpoint
      @endpoint ||= build
    end
  end
end
