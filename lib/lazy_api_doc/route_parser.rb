module LazyApiDoc
  class RouteParser
    def self.find_by(example)
      r = routes.find do |r|
        r['verb'].include?(example.verb) && example.params.slice(*r['defaults'].keys) == r['defaults']
      end
    end

    def self.routes
      return @routes if defined?(@routes)

      @routes = Rails.application.routes.routes.map { |route| format(route) }
    end

    def self.format(route)
      route = ActionDispatch::Routing::RouteWrapper.new(route)
      {
        'doc_path' => route.path.gsub("(.:format)", "").gsub(/(:\w+)/, '{\1}').delete(":"),
        'path_params' => route.path.gsub("(.:format)", "").scan(/:\w+/).map { |p| p.delete(":") },
        'controller' => route.controller,
        'action' => route.action,
        'verb' => route.verb.split('|'),
        'defaults' => route.defaults.transform_keys(&:to_s)
      }
    end
  end
end
