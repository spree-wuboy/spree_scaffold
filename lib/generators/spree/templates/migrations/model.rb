class CreateSpree<%= class_name.pluralize %> < ActiveRecord::Migration
  def up
    create_table :spree_<%= table_name %> do |t|
<% attributes.each do |attribute| -%>
<% next if attribute.type == :image || attribute.type == :file -%>
   <%- if attribute.type == :polymorphic -%>
      t.string :<%= attribute.name -%>_type
      t.integer :<%= attribute.name -%>_id
   <%- else -%>
      t.<%= attribute.type %> :<%= attribute.name %> <%= options[:default].keys.include?(attribute.name) ? ", default: #{(attribute.type == :boolean || attribute.type == :integer) ? options[:default][attribute.name] : "'#{options[:default][attribute.name]}'"}" : ""%>
   <%- end -%>
<% end -%>
<% unless options[:skip_timestamps] -%>
      t.timestamps
<% end -%>
    end

<% attributes.each do |attribute| -%>
  <%- if attribute.name == "deleted_at" || options[:fk].values.include?(attribute.name) || options[:search].include?(attribute.name) -%>
    <%- if attribute.type == "polymorphic" -%>
    add_index :spree_<%= table_name %>, [:<%=attribute.name%>_type, :<%=attribute.name%>_id] <%=options[:unique].include?(attribute.name) ? ", unique: true" : ""%>
    <%- else -%>
    add_index :spree_<%= table_name %>, :<%=attribute.name%> <%=options[:unique].include?(attribute.name) ? ", unique: true" : ""%>
    <%- end -%>
  <%- end -%>
<% end -%>

<% attributes.each do |attribute| -%>
<% if attribute.type == :image || attribute.type == :file -%>
    add_attachment :spree_<%= table_name %>, :<%= attribute.name %>
<% end -%>
<% end -%>
<% if options[:i18n].any? -%>
    #translation tables
    Spree::<%= class_name %>.reset_column_information
    Spree::<%= class_name %>.create_translation_table!({
    <% attributes.each do |attribute| -%>
    <% next unless options[:i18n].include? attribute.name -%>
          <%= attribute.name %>: :<%= attribute.type %>,
    <% end -%>
    })
<% end -%>
  end

  def down
<% if options[:i18n].any? -%>
    #translation tables
Spree::<%= class_name %>.drop_translation_table!
<% end -%>
    drop_table :spree_<%= table_name %>
  end
end
