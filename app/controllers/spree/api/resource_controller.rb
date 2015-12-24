module Spree
  module Api
    class ResourceController < BaseController
      before_action :load_resource

      protected


      def collection_actions
        [:index]
      end

      def action
        params[:action].to_sym
      end

      def model_class
        sub_namespace = sub_namespace_parts.map { |s| s.capitalize }.join('::')
        sub_namespace = "#{sub_namespace}::" if sub_namespace.length > 0
        "Spree::#{sub_namespace}#{controller_name.classify}".constantize
      end

      # This method should be overridden when object_name does not match the controller name
      def object_name
        controller_name.singularize
      end

      private

      def sub_namespace_parts
        controller_path.split('/')[1..-2]
      end

      def resource_not_found
        flash[:error] = flash_message_for(model_class.new, :not_found)
        redirect_to collection_url
      end

      def find_resource
        model_class.accessible_by(current_ability, :read).find(params[:id])
      end

      def collection
        model_class.where(nil)
      end

      def load_resource
        if member_action?
          @object ||= find_resource

          # call authorize! a third time (called twice already in Admin::BaseController)
          # this time we pass the actual instance so fine-grained abilities can control
          # access to individual records, not just entire models.
          authorize! action, @object

          instance_variable_set("@#{object_name}", @object)
        else
          @collection ||= collection

          # note: we don't call authorize here as the collection method should use
          # CanCan's accessible_by method to restrict the actual records returned

          instance_variable_set("@#{controller_name}", @collection)
        end
      end

      def member_action?
        !collection_actions.include? action
      end
    end
  end
end