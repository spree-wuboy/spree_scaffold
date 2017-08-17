require 'rails/generators/named_base'

module Spree
  module Generators
    class ScaffoldGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration

      source_root File.expand_path('../../templates', __FILE__)

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
      class_option :nested, type: :array, default: [], required: false, desc: 'nested attributes(comments, ingredients), you must make sure log/scaffold.log already have the class'
      class_option :cache, type: :boolean, default: false, required: false, desc: 'make a simple cache mechanism'
      class_option :model_class, type: :string, required: false, desc: 'different model class than Spree::Model'
      class_option :add_by, type: :boolean, default: false, required: false, desc: 'add created_by and updated_at'

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
        if options[:model_class]
          template 'model.rb', "app/models/#{options[:model_class].gsub("::", "/").downcase}.rb"
        else
          template 'model.rb', "app/models/spree/#{singular_name}.rb"
        end
      end

      def create_controller
        create_nested
        template 'controller.rb', "app/controllers/spree/admin/#{plural_name}_controller.rb"
      end

      def create_api_controller
        template 'api_controller.rb', "app/controllers/spree/api/v1/#{plural_name}_controller.rb"
      end

      def create_views
        create_nested
        %w[index new edit _form show _object _search].each do |view|
          template "views/#{view}.html.erb", "app/views/spree/admin/#{plural_name}/#{view}.html.erb"
        end

        %w[index batch show _object].each do |pdf|
          template "views/#{pdf}.pdf.erb", "app/views/spree/admin/#{plural_name}/#{pdf}.pdf.erb"
        end
      end

      def create_api_views
        %w[index show].each do |view|
          template "views/#{view}.v1.rabl", "app/views/spree/api/v1/#{plural_name}/#{view}.v1.rabl"
        end
      end

      def create_assets
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
      end

      def create_samples
        template "samples.rb", "db/samples/spree/#{plural_name}.rb"
      end

      def create_task
        task_path = "lib/tasks/load_samples.rake"
        template "load_samples.rake", task_path
        inject_into_file task_path, %Q{
        path = File.expand_path(File.join(Rails.root, 'db','samples','spree','#{plural_name}.rb'))
        require path if !$LOADED_FEATURES.include?(path)
        }, before: /puts \"Loaded samples\"/
      end

      def create_logs
        log_path = "config/scaffold.conf"
        create_file log_path unless File.exist?(File.join(destination_root, log_path))
        gsub_file log_path, /rails g spree:scaffold #{name} .*\n/, ""
        append_file log_path, "rails g spree:scaffold #{name} #{attributes.map {|a| "#{a.name}:#{a.type}"}.join(" ")} #{options.map {|o, v| v.present? ? "--#{o}=#{v.is_a?(Array) ? v.join(" ") : v.is_a?(Hash) ? v.map {|k1, v1| "#{k1}:#{v1}"}.join(" ") : v}" : ''}.join(" ")}\n".force_encoding("ASCII-8BIT")
      end

      def create_locale
        current_locales = ["en", "zh-TW"]
        locales = (options[:locale].keys + current_locales).uniq
        locales.each do |locale|
          @name = options[:locale][locale] ? options[:locale][locale].force_encoding("ASCII-8BIT") : singular_name
          if current_locales.include?(locale) && locale != "en"
            template "locales/#{locale}.yml", "config/locales/#{plural_name}.#{locale}.yml"
          else
            @locale = locale
            template "locales/locale.yml", "config/locales/#{plural_name}.#{locale}.yml"
          end
        end
      end

      def create_deface_override
        template 'overrides/add_sub_menu.html.erb.deface', "app/overrides/spree/admin/shared/sub_menu/_scaffold/add_#{singular_name}_menu.html.erb.deface"
      end

      def create_translation_template
        return unless i18n?
        template 'views/translation_form.html.erb', "app/views/spree/admin/translations/#{singular_name}.html.erb"
      end

      def create_routes
        append_file 'config/routes.rb', routes_text
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
        migration_template 'migrations/model.rb', "db/migrate/create_spree_#{plural_name}.rb"
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

      def add_by?
        options[:add_by]
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

      def presence_not_boolean
        options[:presence].select{|p| self.attributes_hash[p].type != :boolean}
      end

      def presence_boolean
        options[:presence].select{|p| self.attributes_hash[p].type == :boolean}
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
            if line.include?("rails g spree:scaffold #{nested.singularize}")
              @nested_hash[nested] = line.gsub(("rails g spree:scaffold #{nested.singularize}"), "").gsub(/--.*/, "").split(" ").map {|s| {:name => s.split(":")[0], :type => s.split(":")[1].to_sym}}
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
