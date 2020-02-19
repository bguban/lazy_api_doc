require 'rails/generators'

module LazyApiDoc
  module Generators
    class InstallGenerator < Rails::Generators::Base
      def code_that_runs2
        puts "Hi"
      end
    end
  end
end
