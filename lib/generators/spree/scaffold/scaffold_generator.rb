require 'rails/generators/named_base'

module Spree
  module Generators
    class ScaffoldGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration

      source_root File.expand_path('../../templates', __FILE__)

      argument :attributes, type: :array, default: [], banner: 'field:type field:type'
      class_option :locale, type: :hash, default: {}, required: false, desc: 'additional locale (locale:translation_name)'
      class_option :fk, type: :hash, default: {}, required: false, desc: 'foreign key (reference:fk_id)'
      class_option :search, type: :array, default: [], required: false, desc: 'search/index fields'
      class_option :i18n, type: :array, default: [], required: false, desc: 'translated fields'
      class_option :skip_timestamps, type: :boolean, default: false, required: false, desc: 'skip timestamps'
      class_option :presence, type: :array, default: [], required: false, desc: 'validate presence'
      class_option :unique, type: :array, default: [], required: false, desc: 'validate uniqueness'

      def self.next_migration_number(path)
        if @prev_migration_nr
          @prev_migration_nr = @prev_migration_nr += 1
        else
          @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
        end
      end

      def create_model
        template 'model.rb', "app/models/spree/#{singular_name}.rb"
      end

      def create_controller
        template 'controller.rb', "app/controllers/spree/admin/#{plural_name}_controller.rb"
      end

      def create_api_controller
        template 'api_controller.rb', "app/controllers/spree/api/v1/#{plural_name}_controller.rb"
      end

      def create_views
        %w[index new edit _form show].each do |view|
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

      def create_migrations
        migration_template 'migrations/model.rb', "db/migrate/create_spree_#{plural_name}.rb"
      end

      def create_samples
        template "samples.rb", "db/samples/#{plural_name}.rb"
      end

      def create_task
        template "task.rake", "lib/tasks/#{singular_name}.rake"
      end

      def create_initializers
        log_path = "log/scaffold.log"
        create_file log_path unless File.exist?(File.join(destination_root, log_path))
        append_file log_path, "rails g spree:scaffold #{name} #{attributes.map{|a| "#{a.name}:#{a.type}"}.join(" ")} #{options.map{|o,v| v.present? ? "--#{o}=#{v.is_a?(Array) ? v.join(" ") : v.is_a?(Hash) ? v.map{|k1,v1| "#{k1}:#{v1}"}.join(" ") : v}" : ''}.join(" ")}\n".force_encoding("ASCII-8BIT")
      end

      def create_locale
        current_locales = ["en", "zh-TW"]
        locales = (options[:locale].keys + current_locales).uniq
        locales.each do |locale|
          @name = options[:locale][locale] ? options[:locale][locale].force_encoding("ASCII-8BIT") : singular_name
          if current_locales.include?(locale) && locale != "en"
            template "locales/#{locale}.yml", "config/locales/#{plural_name}.#{locale}.yml"
            template "locales/spree_scaffold.#{locale}.yml", "config/locales/spree_scaffold.#{locale}.yml"
          else
            @locale = locale
            template "locales/locale.yml", "config/locales/#{plural_name}.#{locale}.yml"
            template "locales/spree_scaffold.yml", "config/locales/spree_scaffold.#{locale}.yml"
          end
        end
      end

      def create_deface_override
        template 'overrides/add_scaffold_menu.html.erb.deface', "app/overrides/spree//admin/shared/_main_menu/add_scaffold_menu.html.erb.deface"
        template 'overrides/add_sub_menu.html.erb.deface', "app/overrides/spree/admin/shared/sub_menu/_scaffold/add_#{singular_name}_menu.html.erb.deface"
      end

      def create_translation_template
        return unless i18n?
        template 'views/translation_form.html.erb', "app/views/spree/admin/translations/#{singular_name}.html.erb"
      end

      def create_routes
        append_file 'config/routes.rb', routes_text
      end

      def create_readme
        readme "USAGE"
      end

      protected

      def sortable?
        self.attributes.find { |a| a.name == 'position' && a.type == :integer }
      end

      def has_attachments?
        self.attributes.find { |a| a.type == :image || a.type == :file }
      end

      def slugged?
        self.attributes.find { |a| a.name == 'slug' && a.type == :string }
      end

      def i18n?
        options[:i18n].any?
      end

      private

      def routes_text
        <<-EOS

Spree::Core::Engine.add_routes do
  namespace :admin do
    resources :#{plural_name} do
      collection do
        get :batch
        get :check_all
        post :update_positions
      end
      member do
        get :check
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
