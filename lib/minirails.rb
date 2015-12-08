require "minirails/version"

module Minirails
  class << self
    def run(argv)
      case argv[0]
      when "--init"
        init
      when "--fast"
        fast
      when "--help", nil
        help
      else
        if argv[0].start_with?("--")
          help
        else
          start(argv[0], argv[1])
        end
      end
    end

    def help
      puts <<-EOS
Usage: #$0 [OPTIONS] [FILE]

$ #$0 myapp.rb

OPTIONS:
  --help  Show this message
  --init  Create new sample app
  --fast  Setup faster app loading
      EOS
    end

    def init
      File.open("myapp.rb", "w") do |f|
        f.write File.read(File.expand_path("../../test/apps/hello.rb", __FILE__))
      end

      puts "You new app has been created! You can strat it with $ minirails myapp.rb"
    end

    def fast
      File.open("Gemfile", "w") do |f|
        f.puts %Q|source "https://rubygems.org"|
        f.puts %Q|gem "minirails"|
      end

      system "bundle install"
      system "bundle binstubs minirails --force"

      puts "Now you can use much faster bin/minirails instead of minirails"
    end

    def start(specfile, num = nil)
      self.builder = Builder.new(specfile)
      num ? builder.start(num.to_i) : builder.spawn
    end

    attr_accessor :builder
  end


  class Builder < Struct.new(:specfile)

    # DSL API
    def define(name = nil, opts = {}, &block)
      type = opts[:type] || :rails
      klazz = {
        rails:  RailsApp,
        rack:   RackApp,
        blank:  App
      }[type]

      apps << klazz.new(name, block)
    end

    # internals
    def start(num)
      boot
      apps[num].call
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
      load specfile
    end
  end

  class App < Struct.new(:name, :block)
    def call
      block.call
    end
  end

  class RackApp < Struct.new(:name, :block)
    def call
      require "rack"
      Rack::Handler::WEBrick.run(endpoint, :Port => ENV["PORT"])
    end

    def endpoint
      block.call
    end
  end

  class RailsApp < RackApp
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
        # run migrations in order they were defined in source file
        ActiveRecord::Migration.descendants.sort_by {|c|
          c.instance_methods(false).map {|m|
            c.instance_method(m).source_location.last
          }.min
        }.each {|e| e.migrate :up }
      end

      # and finally return app object
      app
    end

    def endpoint
      $stderr.puts "--> loading rails"
      require "action_controller"
      require "rails"
      $stderr.puts "--> loading app"

      make_endpoint
    end

    def make_endpoint
      build
    rescue NameError => e
      # autoloading has some crazy weird error
      # and we can't just require activerecord upfront
      # because if app is not using it there will
      # be no database configuration
      case e.message
      when /uninitialized constant.*ActiveRecord/
        $stderr.puts "--> loading activerecord"
        require "active_record/railtie"
      else
        raise e
      end

      make_endpoint
    end
  end
end

# Public DSL API
def define(*args, &block)
  Minirails.builder.define(*args, &block)
end
