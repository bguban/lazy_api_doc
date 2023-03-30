require 'cgi'

module LazyApiDoc
  class Generator
    EXCLUDED_PARAMS = ["controller", "action", "format"]

    attr_reader :examples

    def initialize
      @examples = []
    end

    def add(example)
      return if example['controller'] == "anonymous" # don't handle virtual controllers

      @examples << example
    end

    def clear
      @examples = []
    end

    def result
      result = {}
      @examples.map { |example| OpenStruct.new(example) }.sort_by(&:source_location)
               .group_by { |ex| [ex.controller, ex.action] }
               .each do |_, examples|
        first = examples.first
        route = ::LazyApiDoc::RouteParser.new(first.controller, first.action, first.verb).route
        next if route.nil? # TODO: think about adding such cases to log

        doc_path = route['doc_path']
        result[doc_path] ||= {}
        result[doc_path].merge!(example_group(first, examples, route))
      end
      result
    end

    private

    def example_group(example, examples, route) # rubocop:disable Metrics/AbcSize
      {
        example['verb'].downcase => {
          "tags" => [example.controller || 'Ungrouped'],
          "description" => example["description"].capitalize,
          "summary" => example.action,
          "parameters" => path_params(route, examples) + query_params(route, examples),
          "requestBody" => body_params(route, examples),
          "responses" => examples.group_by { |ex| ex.response['code'] }.map do |code, variants|
            [
              code,
              {
                "description" => variants.first["description"].capitalize,
                "content" => {
                  example.response['content_type'] => {
                    "schema" => ::LazyApiDoc::VariantsParser.new(variants.map { |v| parse_body(v.response) }).result
                  }
                }
              }
            ]
          end.to_h # rubocop:disable Style/MultilineBlockChain
        }.reject { |_, v| v.nil? }
      }
    end

    def parse_body(response)
      if response['content_type'].match?("json")
        JSON.parse(response['body'])
      else
        "Not a JSON response"
      end
    rescue JSON::ParserError
      response['body']
    end

    def path_params(route, examples)
      path_variants = examples.map { |example| example.params.slice(*route['path_params']) }
      ::LazyApiDoc::VariantsParser.new(path_variants).result["properties"].map do |param_name, schema|
        {
          'in' => "path",
          'required' => true,
          'name' => param_name,
          'schema' => schema
        }
      end
    end

    def query_params(route, examples)
      query_variants = examples.map do |example|
        _path, query = example.request['full_path'].split('?')

        params = query ? CGI.parse(query).map { |k, v| [k.gsub('[]', ''), k.match?('\[\]') ? v : v.first] }.to_h : {}
        params.merge!(example.params.except(*EXCLUDED_PARAMS, *route['path_params'])) if %w[GET DELETE HEAD].include?(example['verb'])
        params
      end

      parsed = ::LazyApiDoc::VariantsParser.new(query_variants).result
      parsed["properties"].map do |param_name, schema|
        {
          'in' => "query",
          'required' => parsed['required'].include?(param_name),
          'name' => param_name,
          'schema' => schema
        }
      end
    end

    def body_params(route, examples)
      first = examples.first
      return unless %w[POST PATCH PUT].include?(first['verb'])

      variants = examples.map { |example| example.params.except(*EXCLUDED_PARAMS, *route['path_params']) }
      {
        'content' => {
          first.content_type => {
            'schema' => ::LazyApiDoc::VariantsParser.new(variants).result
          }
        }
      }
    end
  end
end
