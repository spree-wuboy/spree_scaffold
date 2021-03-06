class CreateSpree<%= class_name.pluralize %> < ActiveRecord::Migration[5.0]
  def up
    create_table :spree_<%= table_name %><%=options[:force] ? ", :force => true" : ""%> do |t|
<% attributes.each do |attribute| -%>
<% next if attribute.type == :image || attribute.type == :file -%>
   <%- if attribute.type == :polymorphic -%>
      t.string :<%= attribute.name -%>_type
      t.integer :<%= attribute.name -%>_id
   <%- else -%>
      t.<%= attribute.type %> :<%= attribute.name %> <%= options[:default].keys.include?(attribute.name) ? ", default: #{options[:enum].keys.include?(attribute.name) ? enum_index(attribute.name, options[:default][attribute.name]) : (attribute.type == :boolean || attribute.type == :integer) ? options[:default][attribute.name] : "'#{options[:default][attribute.name]}'"}" : ""%>
   <%- end -%>
<% end -%>
   <%- if updated_by? -%>
      t.integer :created_by_id
      t.integer :updated_by_id
   <%- end -%>
<% unless options[:skip_timestamps] -%>
      t.timestamps
<% end -%>
    end

<% attributes.each do |attribute| -%>
  <%- if attribute.name == "deleted_at" || options[:fk].values.include?(attribute.name) || (options[:search].include?(attribute.name) && attribute.type != :text ) -%>
    <%- if attribute.type == :polymorphic -%>
    add_index :spree_<%= table_name %>, [:<%=attribute.name%>_type, :<%=attribute.name%>_id] <%=options[:unique].include?(attribute.name) ? ", unique: true" : ""%>
    <%- else -%>
    add_index :spree_<%= table_name %>, :<%=attribute.name%> <%=options[:unique].include?(attribute.name) ? ", unique: true" : ""%>
    <%- end -%>
  <%- end -%>
<% end -%>
<%- attributes.each do |attribute| -%>
<%- if attribute.type == :image || attribute.type == :file -%>
    add_attachment :spree_<%= table_name %>, :<%= attribute.name %>
<%- end -%>
<%- end -%>
<%- if options[:i18n].any? -%>
    #translation tables
    Spree::<%= class_name %>.reset_column_information
    <%- if options[:force] -%>
    drop_table :spree_<%=singular_name%>_translations if table_exists?(:spree_<%=singular_name%>_translations)
    <%- end -%>
    Spree::<%= class_name %>.create_translation_table!({
    <%- attributes.each do |attribute| -%>
    <%- next unless options[:i18n].include? attribute.name -%>
          <%= attribute.name %>: :<%= attribute.type %>,
    <%- end -%>
    })
<%- end -%>
  end

  def down
<% if options[:i18n].any? -%>
    #translation tables
    Spree::<%= class_name %>.drop_translation_table!
<% end -%>
    drop_table :spree_<%= table_name %>
  end
end
