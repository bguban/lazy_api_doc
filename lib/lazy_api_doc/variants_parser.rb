module LazyApiDoc
  class VariantsParser
    OPTIONAL = :lazy_api_doc_optional
    attr_reader :variants

    def initialize(variants)
      @variants = variants.is_a?(Array) ? variants : [variants]
    end

    def result
      @result ||= parse(variants.first, variants)
    end

    def parse(variant, variants)
      variants.delete(OPTIONAL)
      case variant
      when Array
        parse_array(variant, variants)
      when Hash
        parse_hash(variants)
      else
        types_template(variants).merge("example" => variant)
      end
    end

    def types_template(variants)
      types = types_of(variants)
      if types.count == 1
        {
          "type" => types.first
        }
      else
        {
          "oneOf" => types.map { |t| { "type" => t } }
        }
      end
    end

    def types_of(variants)
      variants.map { |v| type_of(v) }.uniq
    end

    def type_of(variant)
      case variant
      when Hash
        "object"
      when NilClass
        "null"
      when TrueClass, FalseClass
        "boolean"
      when String
        type_of_string(variant)
      when Float
        'number'
      else
        variant.class.name.downcase
      end
    end

    def type_of_string(variant)
      case variant
      when /\A\d+\.\d+\z/
        "decimal"
      else
        "string"
      end
    end

    def parse_hash(variants)
      result = types_template(variants)
      variant = variants.select { |v| v.is_a?(Hash) }.reverse_each
                        .each_with_object({}) { |v, res| res.merge!(v) }
      result["properties"] = variant.map do |key, val|
        [
          key.to_s,
          parse(val, variants.compact.map { |v| v.fetch(key, OPTIONAL) })
        ]
      end.to_h
      result["required"] = variant.keys.select { |key| variants.compact.all? { |v| v.key?(key) } }
      result
    end

    def parse_array(variant, variants)
      first = variant.first
      types_template(variants).merge(
        "items"   => parse(first, variants.compact.map(&:first).compact),
        "example" => variant
      )
    end
  end
end
