module Spree
  module ScaffoldHelper
    extend ActiveSupport::Concern
    included do
      attr_accessor :user_id
      before_create :add_create_user
      before_save :add_update_user

      def add_create_user
        self.created_by_id = user_id if user_id && respond_to?(:created_by_id)
      end

      def add_update_user
        self.updated_by_id = user_id if user_id && respond_to?(:updated_by_id)
      end

      # csv
      def self.csv_headers
        csv_column_hash.map(&:name)
      end

      def self.csv_column_hash
        self.columns
      end

      def self.csv_columns(object)
        csv_column_hash.map{|column| csv_value(object,column)}
      end

      def self.csv_value(object, column)
        object.send(column.name)
      end

      def self.to_csv(options={}, params={})
        require 'csv'
        CSV.generate(options) do |csv|
          if params[:q] && params[:q].size > 0
            params[:q].delete(:s)
            conditions = []
            conditions.push(Spree.t("scaffold.report_search_criteria"))
            csv << conditions
            params[:q].each do |key, value|
              conditions = []
              if value.present?
                with_type = get_condition_type(key)
                if with_type[:type] == :boolean || key == "checked" || key.match(/_null$/)
                  value = Spree.t("scaffold.say_#{value.to_bool}")
                end
                condition_name = key == "checked" ? Spree.t("scaffold.search_checked") : with_type[:name] || key
                conditions.push("#{condition_name}#{with_type[:condition] ? " - #{Spree.t("scaffold.conditions.condition_#{with_type[:condition]}")}" : ''}")
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
          if condition_name.end_with?("_#{condition}")
            condition_name = condition_name.gsub("_#{condition}", "")
            with_type = {:type => columns_hash[condition_name] ? columns_hash[condition_name].type : :string, :condition => condition, :name => condition_name}
          end
        end
        if condition_name.end_with?("_is_null") || condition_name.end_with?("_not_null")
          with_type = :boolean
        end
        with_type
      end

      def format_money(amount)
        return 0 unless amount
        Spree::Money.new(amount, no_cents: true, symbol: Spree.t(:dollar), symbol_position: :after).to_s
      end
    end
  end
end