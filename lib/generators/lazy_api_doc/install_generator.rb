require 'rails/generators'
require 'lazy_api_doc'

module LazyApiDoc
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc "Copy base configuration for LazyApiDoc"
      def install
        copy_file 'public/index.html', "#{LazyApiDoc.path}/index.html"
        copy_file 'public/layout.yml', "#{LazyApiDoc.path}/layout.yml"

        append_to_file '.gitignore' do
          <<~TXT

          # LazyApiDoc
          #{LazyApiDoc.path}/api.yml
          #{LazyApiDoc.path}/examples/*.json
          TXT
        end

        install_rspec if Dir.exist?('spec')

        install_minitest if Dir.exist?('test')
      end

      private

      def install_rspec
        copy_file 'support/rspec_interceptor.rb', 'spec/support/lazy_api_doc_interceptor.rb'

        insert_into_file 'spec/rails_helper.rb', after: "RSpec.configure do |config|\n" do
          <<-RUBY
  if ENV['LAZY_API_DOC']
    require 'lazy_api_doc'
    require 'support/lazy_api_doc_interceptor'

    config.include LazyApiDocInterceptor, type: :request
    config.include LazyApiDocInterceptor, type: :controller

    config.after(:suite) do
      # begin: Handle ParallelTests
      # This peace of code handle using ParallelTests (tests runs in independent processes).
      # Just delete this block if you don't use ParallelTests
      if ENV['TEST_ENV_NUMBER'] && defined?(ParallelTests)
        LazyApiDoc.save_examples('rspec')
        ParallelTests.wait_for_other_processes_to_finish if ParallelTests.first_process?
        LazyApiDoc.load_examples
      end
      # end: Handle ParallelTests
      LazyApiDoc.generate_documentation
    end
  end
          RUBY
        end
      end

      def install_minitest
        copy_file 'support/minitest_interceptor.rb', 'test/support/lazy_api_doc_interceptor.rb'

        append_to_file 'test/test_helper.rb' do
          <<~RUBY

            if ENV['LAZY_API_DOC']
              require 'lazy_api_doc'
              require 'support/lazy_api_doc_interceptor'

              class ActionDispatch::IntegrationTest
                include LazyApiDocInterceptor
              end

              Minitest.after_run do
                # begin: Handle ParallelTests
                # This peace of code handle using ParallelTests (tests runs in independent processes).
                # Just delete this block if you don't use ParallelTests
                if ENV['TEST_ENV_NUMBER'] && defined?(ParallelTests)
                  LazyApiDoc.save_examples('minitest')
                  ParallelTests.wait_for_other_processes_to_finish if ParallelTests.first_process?
                  LazyApiDoc.load_examples
                end
                # end: Handle ParallelTests
                LazyApiDoc.generate_documentation
              end
            end
          RUBY
        end
      end
    end
  end
end
