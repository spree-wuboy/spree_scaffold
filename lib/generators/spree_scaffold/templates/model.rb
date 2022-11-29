<%- if options[:model_class] -%>
<%- model_modules.each do |mod| -%>
module <%=mod%>
<%- end -%>
<%="  "-%>class <%=module_class%> < Spree::Core::<%= class_name %>
<%- else -%>
module Spree
  class <%= class_name %> < Spree::Core::<%= class_name %>
<%- end -%>
  end
<%- if options[:model_class] -%>
<%- model_modules.each do |mod| -%>
end
<%- end -%>
<%- else -%>
end
<%- end -%>
