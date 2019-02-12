require 'thor'
require 'rack'
require 'pry'
require 'byebug'
require_relative './lib/router/router'
require_relative './config/routes'
require_relative './lib/middleware/show_exceptions'
require_relative './lib/middleware/static'
Dir[File.join(__dir__, 'app', 'controllers', '*.rb')].each { |file| require file }
Dir[File.join(__dir__, 'app', 'models', '*.rb')].each { |file| require file }


  class RL < Thor
    
    desc "server", "start rails lite server"
    method_option :aliases => "s"
    def server
      router = Router.new
      create_routes(router)

      app = Proc.new do |env|
        req = Rack::Request.new(env)
        res = Rack::Response.new
        router.run(req, res)
        res.finish
      end

      app = Rack::Builder.new do
        use ShowExceptions
        use Static
        run app
      end.to_app

      Rack::Server.start(
      app: app,
      Port: 3000
      )
    end

    desc "console", "start rails lite console"
    method_option :aliases => "c"
    def console
      Pry.start(__FILE__)
    end
  end

