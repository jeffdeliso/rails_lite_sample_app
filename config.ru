require 'rack'
require_relative './lib/router/router'
require_relative './lib/middleware/show_exceptions'
require_relative './lib/middleware/static'
require_relative './config/routes'
require_relative './app/controllers/application_controller'
require_relative './app/models/application_model'
Dir[File.join(__dir__, 'app', 'controllers', '*.rb')].each { |file| require file }
Dir[File.join(__dir__, 'app', 'models', '*.rb')].each { |file| require file }

router = Router.new
create_routes(router)

app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  router.run(req, res)
  res.finish
end

app = Rack::Builder.new do
  use Static
  run app
end.to_app

run app