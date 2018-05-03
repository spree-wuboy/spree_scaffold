module Spree
  module Api
    class ResourceController < BaseController
      before_action :load_resource

      def index
        respond_with(@collection)
      end

      def show
        respond_with(@object)
      end

      def update
        authorize! :update, @object
        if @object.update_attributes(map_nested_attributes_keys(model_class, object_params))
          respond_with(@object, :status => 200, :default_template => :show)
        else
          invalid_resource!(@object)
        end
      end

      def create
        authorize! :create, model_class
        @object = model_class.new(map_nested_attributes_keys(model_class, object_params))
        instance_variable_set("@#{object_name}", @object)
        if @object.save
          respond_with(@object, :status => 201, :default_template => :show)
        else
          invalid_resource!(@object)
        end
      end

      def destroy
        authorize! :destroy, @pbject
        @pbject.destroy
        respond_with(@pbject, :status => 204)
      end

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

      def object_params
        params.require(object_name.to_sym).permit!
      end

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
        if params[:ids]
          model_class.accessible_by(current_ability, :read).where(id: params[:ids].split(',').flatten).distinct.page(params[:page]).per(params[:per_page])
        else
          model_class.accessible_by(current_ability, :read).ransack(params[:q]).result
        end
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