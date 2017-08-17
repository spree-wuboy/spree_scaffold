module Spree
  module ScaffoldConcern
    extend ActiveSupport::Concern

    included do
      helper_method :batch_url, :batch_check_url, :add_check_url, :checks, :checks=,
                    :model_class, :session_key

      respond_to :html, :json, :pdf
      include ::PdfHelper
      helper ::WickedPdfHelper::Assets

      before_action :add_edit_fk, only: [:edit, :new, :update, :create]
      before_action :add_search_fk, only: :index
      before_action :init_checked
      before_action :add_nested_build, only: [:edit, :new]
      create.fails :add_nested_build
      update.fails :add_nested_build
      create.before :add_user_id
      update.before :add_user_id

      def index
        respond_to do |format|
          format.html
          format.pdf do
            render_pdf("#{singular_name}_#{Time.now.to_i.to_s}")
          end
          format.csv {
            data = @collection.to_csv({}, params.to_unsafe_h)
            require 'iconv'
            data = Iconv.new("big5//IGNORE", "utf-8").iconv(data) #remove this if you won't use excel to open csv in traditional Chinese
            send_data data, :filename => "#{singular_name}_#{Time.now.to_i.to_s}.csv",
                      :disposition => 'inline', :type => "text/csv"
          }
        end
      end

      def seacher
        params[:q] ||= {}
        if !params[:q][:created_at_gt].blank?
          params[:q][:created_at_gt] = Time.zone.parse(params[:q][:created_at_gt]).beginning_of_day rescue ""
        end

        if !params[:q][:created_at_lt].blank?
          params[:q][:created_at_lt] = Time.zone.parse(params[:q][:created_at_lt]).end_of_day rescue ""
        end
        base_search = method(:collection).super_method.call
        base_search.includes(includes)
        if params[:q][:checked] == "true" || (params[:include_all] && params[:include_all] == 'false')
          base_search.ransack(params[:q].merge(:id_in => session[session_key]))
        else
          base_search.ransack(params[:q])
        end
      end

      def collection
        return @collection if @collection.present?
        @search = seacher
        if (params[:format] == "pdf" || params[:format] == "csv")
          @collection = @search.result(distinct: true)
        else
          @collection = @search.result(distinct: true).
              page(params[:page]).
              per(params[:per_page] || SpreeScaffold::Config[:per_page])
        end
        @collection
      end

      def show
        respond_to do |format|
          format.html
          format.pdf do
            render_pdf("#{singular_name}_#{Time.now.to_i.to_s}")
          end
        end
      end

      def batch
        collection
        respond_to do |format|
          format.html
          format.pdf do
            render_pdf("#{singular_name}_#{@collection.size}_#{Time.now.to_i.to_s}")
          end
        end
      end

      def batch_checked
        if params[:all].present?
          if params[:all] == "true"
            session[session_key] = collection.pluck(:id)
          elsif params[:all] == "reverse"
            collection.pluck(:id).each do |id|
              session[session_key].include?(id) ? session[session_key].delete(id) : session[session_key].push(id)
            end
          elsif params[:all] == "false"
            session[session_key] = []
          end
        end
        params.delete(:all)
        redirect_to collection_url(:params => params.to_unsafe_h)
      end

      def add_checked
        if params[:checked] && params[:checked] == "true"
          session[session_key].push(@object.id) unless session[session_key].include?(@object.id)
        else
          session[session_key].delete(@object.id) if session[session_key].include?(@object.id)
        end
        render :nothing => true
      end

      def session_key
        session_key = "#{plural_name}_checked".to_sym
      end

      def checks
        session[session_key] ||= []
      end

      def checks= chs
        session[session_key] = chs
      end

      def includes
        # for override
        []
      end

      def add_edit_fk
        # for override
      end

      def add_search_fk
        # for override
      end

      private

      def init_checked
        session[session_key] ||= []
      end

      def render_pdf(name, options={})
        default_options = {:pdf => name,
                           :show_as_html => params[:debug],
                           :layout => "layouts/pdf.pdf",
                           :margin => {
                               :top => 20,
                               :bottom => 20
                           },
                           :header => {
                               :html => {
                                   :template => 'layouts/header.pdf',
                               }
                           },
                           :footer => {
                               :html => {
                                   :template => 'layouts/footer.pdf'
                               }
                           }}
        default_options.merge(options)
        render_with_wicked_pdf(default_options)
      end

      def singular_name
        model_class.model_name.singular
      end

      def plural_name
        model_class.model_name.plural
      end

      def add_nested_build

      end

      def add_user_id
        @object.user_id = spree_current_user.id if spree_current_user
      end
    end
  end
end
