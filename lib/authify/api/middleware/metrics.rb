module Authify
  module API
    module Middleware
      # A middleware for analytics of rack requests
      class Metrics
        def initialize(app)
          @app     = app
          @metrics = Authify::API::Metrics.instance
          @key     = 'rack.action.response'
        end

        def call(env)
          status, header, body = @metrics.time(construct_metric_key('time', env)) do
            @app.call env
          end

          @metrics.increment construct_metric_key('count', env)
          @metrics.increment 'rack.request.count'

          [status, header, body]
        end

        private

        def construct_metric_key(type, env)
          path = Rack::Request.new(env)
                              .path.gsub(%r{/([0-9]+)(/?)}, '/:id\2')
                              .gsub(%r{/}, '.')
                              .chomp('.')
          "#{@key}.#{type}.#{env['REQUEST_METHOD'].downcase}#{path}"
        end
      end
    end
  end
end
