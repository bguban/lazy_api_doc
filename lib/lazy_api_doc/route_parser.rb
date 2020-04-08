module LazyApiDoc
  class RouteParser
    attr_reader :controller, :action, :verb

    def initialize(controller, action, verb)
      @controller = controller
      @action = action
      @verb = verb
    end

    def route
      self.class.routes.find { |r| r[:action] == action && r[:controller] == controller && r[:verb] == verb }
    end

    def self.routes
      return @routes if defined?(@routes)

      all_routes = Rails.application.routes.routes
      require "action_dispatch/routing/inspector"
      inspector = ActionDispatch::Routing::RoutesInspector.new(all_routes)
      @routes = inspector.format(JsonRoutesFormatter.new, ENV["CONTROLLER"])
    end
  end
end

class JsonRoutesFormatter
  def initialize
    @buffer = []
  end

  def result
    @buffer
  end

  def section_title(_title); end

  def section(routes)
    @buffer = routes.map do |r|
      r[:doc_path] = r[:path].gsub("(.:format)", "").gsub(/(:\w+)/, '{\1}').delete(":")
      r[:path_params] = r[:path].gsub("(.:format)", "").scan(/:\w+/).map { |p| p.delete(":").to_sym }
      r[:controller] = r[:reqs].split("#").first
      r[:action] = r[:reqs].split("#").last.split(" ").first
      r
    end
  end

  def header(_routes); end
end
