require 'rails/generators'

module LazyApiDoc
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc "Copy base configuration for LazyApiDoc"
      def install
        copy_file 'public/index.html', 'public/lazy_api_doc/index.html'
        copy_file 'public/layout.yml', 'public/lazy_api_doc/layout.yml'

        install_rspec if Dir.exist?('spec')

        install_minitest if Dir.exist?('test')
      end

      private

      def install_rspec
        copy_file 'support/rspec_interceptor.rb', 'spec/support/lazy_api_doc_interceptor.rb'

        insert_into_file 'spec/rails_helper.rb', after: "RSpec.configure do |config|\n" do
          <<~RUBY
            if ENV['DOC']
              require 'support/lazy_api_doc_interceptor'

              config.include LazyApiDocInterceptor, type: :request
              config.include LazyApiDocInterceptor, type: :controller

              config.after(:suite) do
                LazyApiDoc.save_result
              end
            end
          RUBY
        end
      end

      def install_minitest
        copy_file 'support/minitest_interceptor.rb', 'test/support/lazy_api_doc_interceptor.rb'

        append_to_file 'test/test_helper.rb' do
          <<~RUBY
            if ENV['DOC']
              require 'support/lazy_api_doc_interceptor'

              class ActionDispatch::IntegrationTest
                include LazyApiDocInterceptor
              end

              Minitest.after_run do
                LazyApiDoc.save_result
              end
            end
          RUBY
        end
      end
    end
  end
end
