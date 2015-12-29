require 'faker'

<% attributes.each do |attribute| -%>
<% if options[:fk].values.include?(attribute.name) -%>
<% fk_name = options[:fk].invert[attribute.name] -%>
<% fk_name_plural = options[:fk].invert[attribute.name].pluralize -%>
<% fk_class_name = "Spree::#{options[:fk].invert[attribute.name].camelcase}" -%>
# Spree::Sample.load_sample("<%=fk_name_plural%>")
<%=fk_name%>_count = <%=fk_class_name%>.count
<% end -%>
<% end -%>

100.times.each do
  Faker::Config.locale = <%=options[:locale].keys%>.sample.to_sym if <%=options[:locale].keys%>.any?
  Spree::<%=class_name%>.create({
<% attributes.each do |attribute| -%>
<% if options[:fk].values.include?(attribute.name) -%>
<% fk_name = options[:fk].invert[attribute.name] -%>
<% fk_class_name = "Spree::#{options[:fk].invert[attribute.name].camelcase}" -%>
        <%=fk_name%>: <%=fk_class_name%>.offset(rand(<%=fk_name%>_count)).first,
<% elsif options[:enum].keys.include?(attribute.name) -%>
        <%=attribute.name%>: Random.rand(<%=options[:enum][attribute.name].split(",").size%>),
<% elsif attribute.type == :string -%>
<% if attribute.name.include?("name") -%>
        <%=attribute.name%>: Faker::Name.name,
<% elsif attribute.name != "slug" -%>
        <%=attribute.name%>: Faker::Lorem.word,
<% end -%>
<% elsif attribute.type == :datetime && attribute.name != "deleted_at"-%>
        <%=attribute.name%>: Faker::Time.between(Time.now - 100.days, Time.now - 50.days),
<% elsif attribute.type == :integer -%>
        <%=attribute.name%>: Random.rand(100),
<% elsif attribute.type == :float -%>
    <%=attribute.name%>: Random.rand(100.0).round(2),
<% elsif attribute.type == :boolean -%>
        <%=attribute.name%>: [true, false].sample,
<% end -%>
<% end -%>
  })
end