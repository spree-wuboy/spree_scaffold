module Spree
  class <%= class_name %> < Spree::Base
<% if sortable? -%>
    acts_as_list
<% end -%>
<% if slugged? -%>
    extend FriendlyId
    friendly_id :slug_candidates, use: [:slugged, :finders]
<% end -%>
<% if i18n? -%>
    <%% defined?(SpreeGlobalize) %>
        translates <%= options[:i18n].map { |f| ":#{f}" }.join(', ') %>
        include SpreeGlobalize::Translatable
    <%% end %>
<% end -%>
<% attributes.each do |attribute| -%>
<% if attribute.type == :image -%>
    has_attached_file :<%= attribute.name %>,
                      styles: { large: '600x600>' },
                      default_style: :large,
                      url: '/spree/<%= plural_name %>/:id/:style/:basename.:extension',
                      path: ':rails_root/public/spree/<%= plural_name %>/:id/:style/:basename.:extension',
                      convert_options: { all: '-strip -auto-orient -colorspace sRGB' }

    validates_attachment :<%= attribute.name %>, content_type: { content_type: /\Aimage\/.*\Z/ }
<% elsif attribute.type == :file -%>
    has_attached_file :<%= attribute.name %>,
                      url: '/spree/<%= plural_name %>/:id/:basename.:extension',
                      path: ':rails_root/public/spree/<%= plural_name %>/:id/:basename.:extension'
<% elsif options[:enum].keys.include?(attribute.name) -%>
    enum <%=attribute.name%>: [<%=options[:enum][attribute.name].split(",").map{|v| ":#{v}"}.join(", ")%>]
<% end -%>
<% end -%>
<% if sortable? -%>
    default_scope { order(:position) }
<% end -%>
<% if slugged? -%>
    def slug_candidates
      [:<%= attributes.find { |a| a.type == :string }.name %>]
    end

<% end -%>
<% options[:fk].each do |ref, fk_id| -%>
    belongs_to :<%=ref%>, foreign_key: '<%=fk_id%>'
    # please add has_many <%=plural_name%> to <%=ref%> table
<% end -%>
    self.whitelisted_ransackable_associations = %w[<%=options[:fk].keys.join(" ")%>]
    self.whitelisted_ransackable_attributes = %w[<%=options[:search].join(" ")%> <%=options[:skip_timestamps] ? "" : "created_at updated_at"%>]

<% if options[:presence].any? -%>
    validates_presence_of <%= options[:presence].map{|p| ":#{p}"}.join(", ") -%>
<% end -%>

<% if options[:unique].any? -%>
    validates_uniqueness_of <%= options[:unique].map{|p| ":#{p}"}.join(", ") %>
<% end -%>
    # read http://apidock.com/rails/ActiveRecord/Validations/ClassMethods for more validations
  end
end
