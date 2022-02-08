module LazyApiDocInterceptor
  extend ActiveSupport::Concern

  included do
    %w[get post patch put head delete].each do |method|
      define_method(method) do |*args, **kwargs|
        result = super(*args, **kwargs)
        # self.class.metadata[:doc]
        LazyApiDoc.add_test(self)
        result
      end
    end
  end
end
