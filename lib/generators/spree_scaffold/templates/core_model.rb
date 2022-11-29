<%- if options[:model_class] -%>
<%- model_modules.each do |mod| -%>
module <%=mod%>
<%- end -%>
<%="  "-%>class Core::<%=module_class%> < Spree::Base
<%- else -%>
module Spree
  class Core::<%= class_name %> < Spree::Base
<%- end -%>
    include Spree::ScaffoldHelper
<%- if sortable? -%>
    default_scope { order("position asc") }
<%- else -%>
    default_scope -> {order("#{quoted_table_name}.id desc")}
<%- end -%>
<% if sortable? -%>
    acts_as_list
<%- end -%>
<%- if slugged? -%>
    extend FriendlyId
    friendly_id :slug_candidates, use: [:slugged, :finders]
<%- end -%>
<%- if i18n? -%>
    if defined?(SpreeGlobalize)
      translates <%= options[:i18n].map { |f| ":#{f}" }.join(', ') %>, :fallbacks_for_empty_translations => true
      include SpreeGlobalize::Translatable
    end
<%- end -%>
<%- if attributes.map(&:name).include?("deleted_at") -%>
    acts_as_paranoid
<%- end -%>
<%- if options[:cache] -%>
    after_save :reload_cache
<%- end -%>
<%- attributes.each do |attribute| -%>
<%- if attribute.type == :image -%>
    has_attached_file :<%= attribute.name %>,
                      styles: { mini: '48x48>', small: '300x300>', large: '600x600>' },
                      default_style: :large,
                      url: '/spree/<%= plural_name %>/:id/:style/:basename.:extension',
                      path: ':rails_root/public/spree/<%= plural_name %>/:id/:style/:basename.:extension',
                      convert_options: { all: '-strip -auto-orient -colorspace sRGB' }
    validates_attachment :<%= attribute.name %>, content_type: { content_type: /\Aimage\/.*\Z/ }

<%- elsif attribute.type == :file -%>
    has_attached_file :<%= attribute.name %>,
                      url: '/spree/<%= plural_name %>/:id/:basename.:extension',
                      path: ':rails_root/public/spree/<%= plural_name %>/:id/:basename.:extension'
    do_not_validate_attachment_file_type :<%= attribute.name %>
    attr_accessor :delete_<%= attribute.name %>
    before_validation { <%= attribute.name %>.clear if delete_<%= attribute.name %> == '1' }

<%- elsif attribute.type == :polymorphic -%>
    # please add has_many or has_one relationship to parent model by yourselfs
    # has_many :images, -> { order(:position) }, as: :viewable, dependent: :destroy, class_name: "Spree::Image"
    belongs_to :<%=attribute.name%>, polymorphic: true, touch: true
<%- elsif options[:enum].keys.include?(attribute.name) -%>
    enum <%=attribute.name%>: [<%=options[:enum][attribute.name].split(",").map{|v| ":#{v}"}.join(", ")%>]
<%- end -%>
<%- end -%>

<%- options[:fk].each do |ref, fk_id| -%>
    belongs_to :<%=ref%>, foreign_key: '<%=fk_id%>'
    # please add 'has_many :<%=plural_name%>' to <%=ref%> table
<%- end -%>
    self.whitelisted_ransackable_associations = %w[<%=options[:fk].keys.join(" ")%>]
    self.whitelisted_ransackable_attributes = %w[<%=options[:search].join(" ")%> <%=options[:skip_timestamps] ? "" : "created_at updated_at"%>]
<%- if options[:presence].any? || options[:unique].any? -%>
    # read http://apidock.com/rails/ActiveRecord/Validations/ClassMethods for more validations
<%- end -%>
<%- if presence_not_boolean.any? -%>
    validates_presence_of <%= presence_not_boolean.map{|p| ":#{p}"}.join(", ") %>
<%- end -%>
<%- if presence_boolean.any? -%>
    validates <%= presence_boolean.map{|p| ":#{p}"}.join(", ") %>, :inclusion => { :in => [true, false] }
<%- end -%>
<%- if options[:unique].any? -%>
    validates_uniqueness_of <%= options[:unique].map{|p| ":#{p}"}.join(", ") %>
<%- end -%>
<%- @nested_hash.keys.each do |nested| -%>
<%- if @poly_hash[nested]-%>
    has_many :<%=nested%>, dependent: :destroy, as: :<%=@poly_hash[nested]%>
<%- else -%>
    has_many :<%=nested%>, dependent: :destroy
<%- end -%>
<%- end -%>
<%- @nested_hash.keys.each do |nested| -%>
    accepts_nested_attributes_for :<%=nested%>, allow_destroy: true
<%- end -%>
<%- if slugged? -%>
    def slug_candidates
      [:<%= attributes.find { |a| a.type == :string }.name %>]
    end
<%- end -%>

    def self.csv_headers
      headers = [<%=attributes.map{|attribute| attribute.type == :polymorphic ? "'#{attribute.name}_type','#{attribute.name}_id'" :" '#{attribute.name}'"}.join(',')%>]
      headers.map {|header| I18n.t("activerecord.attributes.spree/<%= singular_name %>.#{header}")}
    end

    def self.csv_columns(<%= singular_name %>)
      [<%=attributes.map{|attribute| attribute.type == :polymorphic ? "#{singular_name}.#{attribute.name}_type,#{singular_name}.#{attribute.name}_id" : "#{singular_name}.#{attribute.name}"}.join(',')%>]
    end

<%- if options[:cache] -%>
    def self.cached
      Rails.cache.fetch("#{Rails.application.class.parent_name.underscore}_<%= class_name.underscore %>") do
        <%=nested? ? "includes(#{@nested_hash.keys.map{|n| ":#{n}"}.join(",")}).all" : "all"%>
      end
    end

    def cached
      self.class.cached
    end
<%- end -%>

    private

<%- if options[:cache] -%>
    def reload_cache
      Rails.cache.delete("#{Rails.application.class.parent_name.underscore}_<%= class_name.underscore %>")
      cached
    end
<%- end -%>
  end
<%- if options[:model_class] -%>
<%- model_modules.each do |mod| -%>
end
<%- end -%>
<%- else -%>
end
<%- end -%>
