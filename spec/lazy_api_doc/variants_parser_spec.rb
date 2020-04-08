RSpec.describe LazyApiDoc::VariantsParser do
  let(:parser) { LazyApiDoc::VariantsParser.new(variants) }

  context "with simple types" do
    let(:variants) { [{ a: 1, b: "s", c: "1.1", d: true, e: nil }, { a: 2, b: "v", c: "2.3", d: false, e: nil }] }

    it "returns openapi structure" do
      expect(parser.result).to eq(
        "type" => "object",
        "properties" => {
          "a" => { "type" => "integer", "example" => 1 },
          "b" => { "type" => "string",  "example" => "s" },
          "c" => { "type" => "decimal", "example" => "1.1" },
          "d" => { "type" => "boolean", "example" => true },
          "e" => { "type" => "null",    "example" => nil }
        },
        "required" => %i[a b c d e]
      )
    end
  end

  context "with complex types" do
    let(:variants) { [{ a: [1, 2], h: {} }, { a: [3, 4], h: {} }] }

    it "returns openapi structure" do
      expect(parser.result).to eq(
        "type" => "object",
        "properties" => {
          "a" => {
            "type" => "array",
            "items" => { "type" => "integer", "example" => 1 },
            "example" => [1, 2]
          },
          "h" => {
            "type" => "object",
            "properties" => {},
            "required" => []
          }
        },
        "required" => %i[a h]
      )
    end
  end

  context "with mixed types" do
    let(:variants) { [{ a: 1 }, { a: "foo" }, {}] }

    it "returns openapi structure" do
      expect(parser.result).to eq(
        "type" => "object",
        "properties" => {
          "a" => {
            "oneOf" => [{ "type" => "integer" }, { "type" => "string" }],
            "example" => 1
          }
        },
        "required" => []
      )
    end
  end
end
