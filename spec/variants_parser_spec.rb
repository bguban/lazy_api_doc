RSpec.describe LazyApiDoc::VariantsParser do
  let(:parser) { LazyApiDoc::VariantsParser.new(variants) }

  context "simple types" do
    let(:variants) { [{ a: 1, b: "s", c: "1.1", d: true, e: nil }, { a: 2, b: "v", c: "2.3", d: false, e: nil }] }

    it "returns openapi structure" do
      expect(parser.result).to eq(
        "type" => "object",
        "required" => true,
        "properties" => {
          "a" => {
            "type" => "integer",
            "example" => 1,
            "required" => true
          },
          "b" => {
            "type" => "string",
            "example" => "s",
            "required" => true
          },
          "c" => {
            "type" => "decimal",
            "example" => "1.1",
            "required" => true
          },
          "d" => {
            "type" => "boolean",
            "example" => true,
            "required" => true
          },
          "e" => {
            "type" => "null",
            "example" => nil,
            "required" => true,
          }
        }
      )
    end
  end

  context "complex types" do
    let(:variants) { [{ a: [1, 2], h: {} }, { a: [3, 4], h: {} }] }

    it "returns openapi structure" do
      expect(parser.result).to eq(
        "type" => "object",
        "required" => true,
        "properties" => {
          "a" => {
            "type" => "array",
            "example" => [1, 2],
            "required" => true,
            "items" => {
              "example" => 1,
              "required"=> true,
              "type" => "integer"
            }
          },
          "h" => {
            "type" => "object",
            "required" => true,
            "properties" => {}
          }
        }
      )
    end
  end

  context "mixed types" do
    let(:variants) { [{ a: 1 }, { a: "foo" }, {}] }

    it "returns openapi structure" do
      expect(parser.result).to eq(
        "type" => "object",
        "required" => true,
        "properties" => {
          "a" => {
            "oneOf"=>[
              { "type" => "integer" },
              { "type" => "string" }
            ],
            "example" => 1,
            "required" => false
          }
        }
      )
    end
  end
end
