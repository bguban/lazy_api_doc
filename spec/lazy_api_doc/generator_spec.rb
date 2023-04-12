RSpec.describe LazyApiDoc::Generator do
  describe '#query_params' do
    subject do
      LazyApiDoc::Generator.new.send(
        :query_params,
        { 'verb' => ['GET'], 'defaults' => {} },
        [OpenStruct.new('request' => { 'full_path' => "http://example.com?#{query}" }, 'params' => { 'f' => [1, 2, 3] },
                        'verb' => 'GET')]
      )
    end

    let(:query) { 'a=&b=1&c[]=1&d[]=2&d[]=3&e[a]=1&e[b]=2' }

    it {
      expect(subject).to eq(
        [
          { "in" => "query", "required" => true, "name" => "a", "schema" => { "type" => "string", "example" => "" } },
          { "in" => "query", "required" => true, "name" => "b", "schema" => { "type" => "string", "example" => "1" } },
          { "in" => "query", "required" => true, "name" => "c",
"schema" => { "type" => "array", "items" => { "type" => "string", "example" => "1" }, "example" => ["1"] } },
          { "in" => "query", "required" => true, "name" => "d",
"schema" => { "type" => "array", "items" => { "type" => "string", "example" => "2" }, "example" => ["2", "3"] } },
          # TODO: not sure that object should be treated as several strings
          { "in" => "query", "required" => true, "name" => "e[a]",
"schema" => { "type" => "string", "example" => "1" } },
          { "in" => "query", "required" => true, "name" => "e[b]",
"schema" => { "type" => "string", "example" => "2" } },
          { "in" => "query", "required" => true, "name" => "f",
"schema" => { "type" => "array", "items" => { "type" => "integer", "example" => 1 }, "example" => [1, 2, 3] } }
        ]
      )
    }
  end
end
