module LazyApiDoc
  class RouteParser
    attr_reader :controller, :action, :verb

    def initialize(controller, action, verb)
      @controller = controller
      @action = action
      @verb = verb
    end

    def route
      self.class.routes.find { |r| r['action'] == action && r['controller'] == controller && r['verb'].include?(verb) }
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
        'verb' => route.verb.split('|')
      }
    end
  end
end
