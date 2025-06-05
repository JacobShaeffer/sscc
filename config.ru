# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

ActiveRecord::Base.logger.level = 1

run Rails.application
Rails.application.load_server
