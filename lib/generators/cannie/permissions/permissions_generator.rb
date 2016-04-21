module Cannie
  # Cannie generators namespace
  module Generators
    # Generator of dummy permissions class
    class PermissionsGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def generate_permissions
        copy_file 'permissions.rb', 'app/models/permissions.rb'
      end
    end
  end
end
