object false

child(@<%=plural_name%> => :<%=plural_name%>) do
  attributes *<%=singular_name%>_attributes
end

if @<%=plural_name%>.respond_to?(:num_pages)
  node(:count) { @<%=plural_name%>.count }
  node(:current_page) { params[:page] || 1 }
  node(:pages) { @<%=plural_name%>.num_pages }
end
