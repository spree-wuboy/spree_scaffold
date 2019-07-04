module Spree
  module Admin
    module Core
      class <%= class_name.pluralize %>Controller < ScaffoldController

        def includes
          [<%=options[:fk].keys.map{|fk| ":#{fk}"}.join(",")%>]
        end

        def batch_url(options = {})
          batch_admin_<%=plural_name%>_url(options)
        end

        def batch_check_url(options = {})
          batch_checked_admin_<%=plural_name%>_url(options)
        end

        def add_check_url(options = {})
          add_checked_admin_<%= singular_name %>_url(options)
        end

      <%- if options[:model_class] -%>
        def model_class
          @model_class = <%=options[:model_class]%>
        end
      <%- end -%>

        protected

        def permitted_resource_params
          params[resource.object_name].present? ? params.require(resource.object_name).permit! : ActionController::Parameters.new
        end

        private

        def add_edit_fk
  <% attributes.each do |attribute| -%>
  <% if options[:fk].values.include?(attribute.name) -%>
  <% fk_class_name = "Spree::#{options[:fk].invert[attribute.name].camelcase}" -%>
        if defined?(<%=fk_class_name%>)
          @select_<%=attribute.name%> = <%=fk_class_name%>.all
        end
  <% elsif attribute.type == :polymorphic -%>
          @select_<%=attribute.name%>_type = model_class.select(:<%=attribute.name%>_type).distinct
  <% end -%>
  <% end -%>
        end

        def add_search_fk
  <%- options[:search].each do |column| -%>
  <%- if options[:fk].values.include?(column) -%>
  <%- fk_class_name = "Spree::#{options[:fk].invert[column].camelcase}" -%>
          if defined?(<%=fk_class_name%>)
            # override map{|s| [s.id, s.id]} to .where(condition).map{|s| [s.title, s.key]}
            @search_<%=column%>_options = <%=fk_class_name%>.all.map{|s| [s.id, s.id]}
          end
  <%- end -%>
  <%- end -%>
        end
      <%- if nested? -%>

        def add_nested_build
          if @object
        <%- @nested_hash.keys.each do |nested| -%>
            @object.<%=nested%>.build
        <%- end -%>
          end
        end
      <%- end -%>
        end
    end
  end
end
