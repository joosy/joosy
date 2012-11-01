require 'action_dispatch/routing/mapper'

module ActionDispatch::Routing::Mapper::Resources
  def resources_with_joosy(*resources, &block)
    resources_without_joosy(*resources, &block).tap do
      namespace = Joosy::Rails::Engine.resources[@scope[:module].to_s] ||= {}
      namespace[resources[0].to_s.singularize] = "#{@scope[:path]}/#{resources[0]}"
    end
  end
  alias_method_chain :resources, :joosy
end
