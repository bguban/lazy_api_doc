require "lazy_api_doc/version"
require "lazy_api_doc/variants_parser"
require "lazy_api_doc/generator"
require "lazy_api_doc/route_parser"
require "yaml"

module LazyApiDoc
  class Error < StandardError; end

  def self.generator
    @generator ||= Generator.new
  end

  def self.add(example)
    generator.add(example)
  end

  def self.add_spec(example)
    add(
      controller: example.request.params[:controller],
      action: example.request.params[:action],
      description: example.class.description,
      source_location: [example.class.metadata[:file_path], example.class.metadata[:line_number]],
      verb: example.request.method,
      params: example.request.params,
      content_type: example.request.content_type.to_s,
      response: {
        code: example.response.status,
        content_type: example.response.content_type.to_s,
        body: example.response.body
      }
    )
  end

  def self.add_test(example)
    add(
      controller: example.request.params[:controller],
      action: example.request.params[:action],
      description: example.name.gsub(/\Atest_/, '').humanize,
      source_location: example.method(example.name).source_location,
      verb: example.request.method,
      params: example.request.params,
      content_type: example.request.content_type.to_s,
      response: {
        code: example.response.status,
        content_type: example.response.content_type.to_s,
        body: example.response.body
      }
    )
  end

  def self.save_result(to: 'public/lazy_api_doc/api.yml', layout: 'public/lazy_api_doc/layout.yml')
    layout = YAML.safe_load(File.read(Rails.root.join(layout)))
    layout["paths"] ||= {}
    layout["paths"].merge!(generator.result)
    File.write(Rails.root.join(to), layout.to_yaml)
  end
end
