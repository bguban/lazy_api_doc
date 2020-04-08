module LazyApiDocInterceptor
  extend ActiveSupport::Concern

  included do
    %w[get post patch put head delete].each do |method|
      define_method(method) do |*args|
        result = super(*args)
        # self.class.metadata[:doc] can be used to document only tests with doc: true metadata
        LazyApiDoc.add_spec(self)
        result
      end
    end
  end
end
