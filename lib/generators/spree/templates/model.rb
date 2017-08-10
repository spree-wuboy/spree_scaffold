module Spree
  class <%= class_name %> < Spree::Base
<% if sortable? -%>
    default_scope { order("position asc") }
<% else -%>
    default_scope -> {order("id desc")}
<% end -%>
<% if sortable? -%>
    acts_as_list
<% end -%>
<% if slugged? -%>
    extend FriendlyId
    friendly_id :slug_candidates, use: [:slugged, :finders]
<% end -%>
<% if i18n? -%>
    if defined?(SpreeGlobalize)
      translates <%= options[:i18n].map { |f| ":#{f}" }.join(', ') %>
      include SpreeGlobalize::Translatable
    end
<%- end -%>
<%- if attributes.map(&:name).include?("deleted_at") -%>
    acts_as_paranoid
<%- end -%>
<% attributes.each do |attribute| -%>
<% if attribute.type == :image -%>
    has_attached_file :<%= attribute.name %>,
                      styles: { mini: '48x48>', small: '300x300>', large: '600x600>' },
                      default_style: :large,
                      url: '/spree/<%= plural_name %>/:id/:style/:basename.:extension',
                      path: ':rails_root/public/spree/<%= plural_name %>/:id/:style/:basename.:extension',
                      convert_options: { all: '-strip -auto-orient -colorspace sRGB' }
    validates_attachment :<%= attribute.name %>, content_type: { content_type: /\Aimage\/.*\Z/ }

<% elsif attribute.type == :file -%>
    has_attached_file :<%= attribute.name %>,
                      url: '/spree/<%= plural_name %>/:id/:basename.:extension',
                      path: ':rails_root/public/spree/<%= plural_name %>/:id/:basename.:extension'
<% elsif attribute.type == :polymorphic -%>
    # please add has_many or has_one relationship to parent model by yourselfs
    # has_many :images, -> { order(:position) }, as: :viewable, dependent: :destroy, class_name: "Spree::Image"
    belongs_to :<%=attribute.name%>, polymorphic: true, touch: true
<% elsif options[:enum].keys.include?(attribute.name) -%>
    enum <%=attribute.name%>: [<%=options[:enum][attribute.name].split(",").map{|v| ":#{v}"}.join(", ")%>]
<% end -%>
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

<% if options[:presence].any? || options[:unique].any? -%>
    # read http://apidock.com/rails/ActiveRecord/Validations/ClassMethods for more validations
<% end -%>
<% options[:nested].each do |nested| -%>
    has_many :<%=nested%>, dependent: :destroy
<% end -%>

<% options[:nested].each do |nested| -%>
    accepts_nested_attributes_for :<%=nested%>, allow_destroy: true
<% end -%>

<% if slugged? -%>
    def slug_candidates
      [:<%= attributes.find { |a| a.type == :string }.name %>]
    end
<% end -%>

    def self.csv_headers
      headers = [<%=attributes.map{|attribute| "'#{attribute.name}'"}.join(',')%>]
      headers.map {|header| I18n.t("activerecord.attributes.spree/<%= singular_name %>.#{header}")}
    end

    def self.csv_columns(<%= singular_name %>)
      [<%=attributes.map{|attribute| "#{singular_name}.#{attribute.name}"}.join(',')%>]
    end

    def self.to_csv(options={}, params={})
      require 'csv'
      CSV.generate(options) do |csv|
        if params[:q]
          params[:q].delete(:s)
          conditions = []
          conditions.push(Spree.t("scaffold.report_search_criteria"))
          csv << conditions
          params[:q].each do |key, value|
            conditions = []
            if value.present?
              with_type = get_condition_type(key)
              if with_type[:type] == :boolean
                value = Spree.t("scaffold.say_#{value.to_bool}")
              end
              conditions.push("#{I18n.t("activerecord.attributes.spree/<%= singular_name %>.#{key}")}#{with_type[:condition] ? Spree.t("scaffold.conditions.#{with_type[:condition]}") : ''}")
              conditions.push(value)
              csv << conditions
            end
          end
        end

        headers = []
        csv_headers.each {|header| headers.push(header)}
        csv << headers

        all.each do |object|
          columns = []
          csv_columns(object).each do |column|
            columns.push(column)
          end
          csv << columns
        end
      end
    end

    def self.get_condition_type(condition_name)
      conditions = ["eq", "not_eq","lt", "gt", "lteq", "gteq",
                    "in", "not_in", "cont", "not_cont", "cont_any",
                    "not_cont_any","cont_all", "not_cont_all",
                    "start", "not_start", "end", "not_end",
                    "true", "not_true" ,"false", "not_false",
                    "present", "blank", "null", "not_null"]
      with_type = {}
      conditions.each do |condition|
        Rails.logger.debug("condition_name=#{condition_name}")
        if condition_name.end_with?("_#{condition}")
          condition_name = condition_name.gsub("_#{condition}")
          with_type = {:type => columns_hash[condition_name].type, :condition => condition}
        end
      end
      if condition_name.end_with?("_is_null") || condition_name.end_with?("_not_null")
        with_type = :boolean
      end
      with_type
    end


<% if options[:cache] -%>
    after_save :reload_cache

    def self.cached
      Rails.cache.fetch("#{Rails.application.class.parent_name.underscore}_<%= class_name.underscore %>") do
        all
      end
    end

    def cached
      self.class.cached
    end

<% end -%>

    private

<% if options[:cache] -%>
    def reload_cache
      Rails.cache.delete("#{Rails.application.class.parent_name.underscore}_<%= class_name.underscore %>")
      cached
    end
<% end -%>
  end
end
