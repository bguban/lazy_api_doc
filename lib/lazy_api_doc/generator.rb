module LazyApiDoc
  class Generator
    attr_reader :examples

    def initialize
      @examples = []
    end

    def add(example)
      return if example[:controller] == "anonymous" # don't handle virtual controllers

      @examples << OpenStruct.new(example)
    end

    def result
      result = {}
      @examples.group_by { |example| [example.controller, example.action] }.map do |_, examples|
        first = examples.first
        route = ::LazyApiDoc::RouteParser.new(first.controller, first.action, first.verb).route
        doc_path = route[:doc_path]
        result[doc_path] ||= {}
        result[doc_path].merge!(example_group(first, examples, route))
      end
      result
    end

    def example_group(example, examples, route)
      {
        route[:verb].downcase => {
          "tags" => [example.controller],
          "description" => example["description"].capitalize,
          "summary" => example.action,
          "parameters" => path_params(route, examples),
          "requestBody" => body_params(route, examples),
          "responses" => examples.group_by { |ex| ex.response[:code] }.map do |code, variants|
            [
              code,
              {
                "content" => {
                  example.response[:content_type] => {
                    "schema" => ::LazyApiDoc::VariantsParser.new(variants.map { |v| parse_body(v.response) }).result
                  }
                }
              }
            ]
          end.to_h
        }
      }
    end

    def parse_body(response)
      if response[:content_type].match?("json")
        JSON.parse(response[:body])
      else
        "Not a JSON response"
      end
    rescue JSON::ParserError
      response[:body]
    end

    def path_params(route, examples)
      variants = examples.map { |example| example.params.slice(*route[:path_params]) }
      ::LazyApiDoc::VariantsParser.new(variants).result["properties"].map do |param_name, schema|
        {
          'in' => "path",
          'name' => param_name,
          'schema' => schema
        }
      end
    end

    def body_params(route, examples)
      return if route[:verb] == "GET"

      first = examples.first
      variants = examples.map { |example| example.params.except("controller", "action", *route[:path_params]) }
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
