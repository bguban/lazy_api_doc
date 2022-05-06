require "lazy_api_doc/version"
require "lazy_api_doc/variants_parser"
require "lazy_api_doc/generator"
require "lazy_api_doc/route_parser"
require "yaml"

module LazyApiDoc
  class Error < StandardError; end

  class << self
    attr_accessor :path, :example_file_ttl

    def configure
      yield self
    end

    def reset!
      config_file = './config/lazy_api_doc.yml'
      config = File.exist?(config_file) ? YAML.safe_load(ERB.new(File.read(config_file)).result) : {}

      self.path = ENV['LAZY_API_DOC_PATH'] || config['path'] || 'public/lazy_api_doc'
      self.example_file_ttl = ENV['LAZY_API_DOC_EXAMPLE_FILE_TTL'] || config['example_file_ttl'] || 1800 # 30 minutes
    end

    def generator
      @generator ||= Generator.new
    end

    def add(lazy_example)
      generator.add(lazy_example)
    end

    def add_spec(rspec_example) # rubocop:disable Metrics/AbcSize
      add(
        'controller' => rspec_example.request.params[:controller],
        'action' => rspec_example.request.params[:action],
        'description' => rspec_example.class.description,
        'source_location' => [rspec_example.class.metadata[:file_path], rspec_example.class.metadata[:line_number]],
        'verb' => rspec_example.request.method,
        'params' => rspec_example.request.params,
        'content_type' => rspec_example.request.content_type.to_s,
        'request' => {
          'query_params' => rspec_example.request.query_parameters,
          'full_path' => rspec_example.request.fullpath
        },
        'response' => {
          'code' => rspec_example.response.status,
          'content_type' => rspec_example.response.content_type.to_s,
          'body' => rspec_example.response.body
        }
      )
    end

    def add_test(mini_test_example) # rubocop:disable Metrics/AbcSize
      add(
        'controller' => mini_test_example.request.params[:controller],
        'action' => mini_test_example.request.params[:action],
        'description' => mini_test_example.name.gsub(/\Atest_/, '').humanize,
        'source_location' => mini_test_example.method(mini_test_example.name).source_location,
        'verb' => mini_test_example.request.method,
        'params' => mini_test_example.request.params,
        'content_type' => mini_test_example.request.content_type.to_s,
        'request' => {
          'query_params' => mini_test_example.request.query_parameters,
          'full_path' => mini_test_example.request.fullpath
        },
        'response' => {
          'code' => mini_test_example.response.status,
          'content_type' => mini_test_example.response.content_type.to_s,
          'body' => mini_test_example.response.body
        }
      )
    end

    def generate_documentation
      layout = YAML.safe_load(File.read("#{path}/layout.yml"))
      layout["paths"] ||= {}
      layout["paths"].merge!(generator.result)
      File.write("#{path}/api.yml", layout.to_yaml)
    end

    def save_examples
      FileUtils.mkdir("#{path}/examples") unless File.exist?("#{path}/examples")
      File.write(
        "#{path}/examples/rspec_#{ENV['TEST_ENV_NUMBER'] || SecureRandom.uuid}.json",
        {
          created_at: Time.now.to_i,
          examples: generator.examples
        }.to_json
      )
    end

    def load_examples
      valid_time = Time.now.to_i - example_file_ttl
      examples = Dir["#{path}/examples/*.json"].flat_map do |file|
        meta = JSON.parse(File.read(file))
        next [] if meta['created_at'] < valid_time # do not handle outdated files

        meta['examples']
      end
      generator.clear
      examples.each { |example| add(example) }
    end
  end
end

LazyApiDoc.reset!
