require 'rails/generators/named_base'

module SpreeScaffold
  module Generators
    class ScaffoldGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      argument :attributes, type: :array, default: [], banner: 'field:type field:type'
      class_option :locale, type: :hash, default: {}, required: false, desc: 'additional locale (locale:name locale:name)'
      class_option :enum, type: :hash, default: {}, required: false, desc: 'enum fields (enum:value1,value2,value3)'
      class_option :default, type: :hash, default: {}, required: false, desc: 'default fields (field:value field:value)'
      class_option :fk, type: :hash, default: {}, required: false, desc: 'foreign key (fk_name:fk_id fk_name:fk_id)'
      class_option :search, type: :array, default: [], required: false, desc: 'search/index fields'
      class_option :i18n, type: :array, default: [], required: false, desc: 'translated fields'
      class_option :skip_timestamps, type: :boolean, default: false, required: false, desc: 'skip timestamps'
      class_option :presence, type: :array, default: [], required: false, desc: 'validate presence'
      class_option :unique, type: :array, default: [], required: false, desc: 'validate uniqueness'
      class_option :html, type: :array, default: [], required: false, desc: 'tinymce html editor fields (html:text_field1,text_field2,text_field3)'
      class_option :nested, type: :array, default: [], required: false, desc: 'nested attributes(comments, ingredients), you must make sure log/scaffold.log already have the class'
      class_option :cache, type: :boolean, default: false, required: false, desc: 'make a simple cache mechanism'
      class_option :model_class, type: :string, required: false, desc: 'different model class than Spree::Model'
      class_option :updated_by, type: :boolean, default: false, required: false, desc: 'add created_by_id and updated_by_id'
      class_option :full_width, type: :boolean, default: false, required: false, desc: 'full width form'
      class_option :gen, type: :string, required: false, desc: 'generate type, default is false, you can use v(view), m(migration+model), c(controller), o(override). e.g. vm will generate view, model, and migration'

      def self.next_migration_number(path)
        if @prev_migration_nr
          @prev_migration_nr = @prev_migration_nr += 1
        else
          @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
        end
      end

      def validate_name
        raise "name is invalid: '#{singular_name}'" if singular_name.include?(":")
      end

      def create_model
        if !options[:gen] || options[:gen].include?("m")
          if options[:model_class]
            template 'model.rb', "app/models/#{options[:model_class].gsub("::", "/").downcase}.rb"
          else
            template 'model.rb', "app/models/spree/#{singular_name}.rb"
          end
        end
      end

      def create_controller
        if !options[:gen] || options[:gen].include?("c")
          create_nested
          template 'controller.rb', "app/controllers/spree/admin/#{plural_name}_controller.rb"
        end
      end

      def create_api_controller
        if !options[:gen] || options[:gen].include?("c")
          template 'api_controller.rb', "app/controllers/spree/api/v1/#{plural_name}_controller.rb"
        end
      end

      def create_views
        if !options[:gen] || options[:gen].include?("v")
          create_nested
          %w[index new edit _form show _object _search].each do |view|
            template "views/#{view}.html.erb", "app/views/spree/admin/#{plural_name}/#{view}.html.erb"
          end

          %w[index batch show _object].each do |pdf|
            template "views/#{pdf}.pdf.erb", "app/views/spree/admin/#{plural_name}/#{pdf}.pdf.erb"
          end
        end
      end

      def create_api_views
        if !options[:gen] || options[:gen].include?("v")
          %w[index show].each do |view|
            template "views/#{view}.v1.rabl", "app/views/spree/api/v1/#{plural_name}/#{view}.v1.rabl"
          end
        end
      end

      def create_assets
        if !options[:gen]
          %w{javascripts stylesheets}.each do |path|
            empty_directory "app/assets/#{path}/spree/frontend"
            empty_directory "app/assets/#{path}/spree/backend"
          end
          assets = ["assets/javascripts/spree/frontend/all.js",
                    "assets/stylesheets/spree/frontend/all.css",
                    "assets/javascripts/spree/backend/all.js",
                    "assets/stylesheets/spree/backend/all.css"]
          assets.each do |path|
            template path, "app/#{path}" unless File.exist?("app/#{path}")
          end
          if i18n?
            inject_into_file "app/assets/javascripts/spree/backend/all.js", "//= require spree/backend/spree_globalize\n", before: /\/\/= require_tree/
            inject_into_file 'app/assets/stylesheets/spree/backend/all.css', " *= require spree/backend/spree_globalize\n", before: / \*= require_tree/
          end

          if nested?
            inject_into_file "app/assets/javascripts/spree/backend/all.js", "//= require spree/backend/spree_scaffold\n", before: /\/\/= require_tree/
          end

          if string_index_columns.any?
            empty_directory "app/assets/javascripts/spree/backend/pickers"
            template "assets/javascripts/spree/backend/pickers/picker.js", "app/assets/javascripts/spree/backend/pickers/#{singular_name}_picker.js"
          end
        end
      end

      def create_samples
        if !options[:gen]
          template "samples.rb", "db/samples/spree/#{plural_name}.rb"
        end
      end

      def create_logs
        log_path = "config/scaffold.conf"
        create_file log_path unless File.exist?(File.join(destination_root, log_path))
        gsub_file log_path, /rails g spree_scaffold:scaffold #{name} .*\n/, ""
        append_file log_path, "rails g spree_scaffold:scaffold #{name} #{attributes.map {|a| "#{a.name}:#{a.type}"}.join(" ")} #{options.map {|o, v| v.present? ? "--#{o}=#{v.is_a?(Array) ? v.join(" ") : v.is_a?(Hash) ? v.map {|k1, v1| "#{k1}:#{v1}"}.join(" ") : v}" : ''}.join(" ")}\n".force_encoding("ASCII-8BIT")
      end

      def create_locale
        if !options[:gen]
          current_locales = ["en"]
          locales = (options[:locale].keys + current_locales).uniq
          locales.each do |locale|
            @plural_title = options[:locale][locale] ? options[:locale][locale].force_encoding("ASCII-8BIT") : class_name.pluralize.titleize
            @singular_title = options[:locale][locale] ? options[:locale][locale].force_encoding("ASCII-8BIT") : class_name.titleize
            if current_locales.include?(locale) && locale != "en"
              template "locales/#{locale}.yml", "config/locales/#{plural_name}.#{locale}.yml"
            else
              @locale = locale
              template "locales/locale.yml", "config/locales/#{plural_name}.#{locale}.yml"
            end
          end
        end
      end

      def create_deface_override
        if !options[:gen] || options[:gen].include?("o")
          template 'overrides/add_sub_menu.html.erb.deface', "app/overrides/spree/admin/shared/sub_menu/_scaffold/add_#{singular_name}_menu.html.erb.deface"
        end
      end

      def create_translation_template
        return unless i18n?
        template 'views/translation_form.html.erb', "app/views/spree/admin/translations/#{singular_name}.html.erb"
      end

      def create_routes
        if !options[:gen]
          append_file 'config/routes.rb', routes_text
        end
      end

      def create_gems
        if locale? || i18n?
          append_file 'Gemfile', %q{
gem 'spree_i18n', github: 'spree-contrib/spree_i18n', branch: 'master'}
        end
        if i18n?
          append_file 'Gemfile', %q{
gem 'spree_globalize', github: 'spree-wuboy/spree_globalize', branch: 'master'}
        end
      end

      def create_readme
        readme "USAGE"
      end

      def create_migrations
        if !options[:gen] || options[:gen].include?("m")
          migration_template 'migrations/model.rb', "db/migrate/create_spree_#{plural_name}.rb"
        end
      end

      protected

      def sortable?
        self.attributes.find {|a| a.name == 'position' && a.type == :integer}
      end

      def has_attachments?
        self.attributes.find {|a| a.type == :image || a.type == :file}
      end

      def slugged?
        self.attributes.find {|a| a.name == 'slug' && a.type == :string}
      end

      def model_modules
        classes = options[:model_class].split("::")
        if classes.size > 1
          classes[0..(classes.size-2)]
        else
          []
        end
      end

      def module_class
        classes = options[:model_class].split("::")
        if classes.size > 1
          classes[classes.size-1]
        else
          options[:model_class]
        end
      end

      def locale?
        options[:locale].any?
      end

      def updated_by?
        options[:updated_by]
      end

      def i18n?
        options[:i18n].any?
      end

      def nested?
        options[:nested].any?
      end

      def enum_values(enum)
        options[:enum][enum].split(",")
      end

      def enum_index(enum, value)
        values = options[:enum][enum].split(",")
        values.index(value)
      end

      def string_index_columns
        self.attributes.select {|a| a.type == :string && options[:search].include?(a.name)}.map{|a| a.name}
      end

      def presence_not_boolean
        options[:presence].select {|p| self.attributes_hash[p].type != :boolean}
      end

      def presence_boolean
        options[:presence].select {|p| self.attributes_hash[p].type == :boolean}
      end

      def attributes_hash
        return @hash if @hash.present?
        @hash = {}
        self.attributes.each do |a|
          @hash[a.name] = a
        end
        @hash
      end

      private

      def create_nested
        log_path = "config/scaffold.conf"
        create_file log_path unless File.exist?(File.join(destination_root, log_path))
        @nested_hash = {}
        File.readlines(log_path).each do |line|
          options[:nested].each do |nested|
            if line.include?("rails g spree:scaffold #{nested.singularize} ") || line.include?("rails g spree_scaffold:scaffold #{nested.singularize} ")
              line = line.gsub(/ [ ]*/, " ").gsub("\n", "")
              nested_options_map = line.sub(/.*? --/, "").split("--")
              nested_options = {}
              nested_options_map && nested_options_map.each do |op|
                nested_options[op.split("=")[0].to_sym] = op.split("=")[1].sub(/ $/, "")
              end
              @nested_hash[nested] = line.gsub("spree:scaffold", "spree_scaffold:scaffold").gsub("rails g spree_scaffold:scaffold #{nested.singularize}", "")
                                         .gsub(/--.*/, "").split(" ").map {|s| {:name => s.split(":")[0], :type => s.split(":")[1].to_sym,
                                                                                :presence => nested_options[:presence] && nested_options[:presence].split(" ") && nested_options[:presence].split(" ").include?(s.split(":")[0]),
                                                                                :html => nested_options[:html] && nested_options[:html].split(" ") && nested_options[:html].split(" ").include?(s.split(":")[0]),
                                                                                :enum => nested_options[:enum] && nested_options[:enum].split(" ") && nested_options[:enum].split(" ").map{|o| o.split(":")[0]}.include?(s.split(":")[0])}}
            end
          end
        end
      end

      def routes_text
        <<-EOS

Spree::Core::Engine.add_routes do
  namespace :admin do
    resources :#{plural_name} do
      collection do
        get :batch
        get :batch_checked
        post :update_positions
      end
      member do
        get :add_checked
      end
    end
  end

  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      resources :#{plural_name} do
      end
    end
  end
end
        EOS

      end
    end
  end
end
