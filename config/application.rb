require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module MyHomeBackend
  class Application < Rails::Application
    config.load_defaults 7.0

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins Rails.env.development? ? 'http://localhost:8080' : ENV['PRODUCTION_FRONT_URL']
        resource '*',
        headers: :any,
        methods: :any,
        credentials: true
      end
    end

    config.action_controller.default_protect_from_forgery = false

    config.eager_load_paths << Rails.root.join('lib')
    config.read_encrypted_secrets = true
    config.time_zone = 'America/Sao_Paulo'

    config.api_only = true
  end
end
