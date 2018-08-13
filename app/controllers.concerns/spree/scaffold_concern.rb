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
      before_action :add_user_id, only: [:update, :create]

      def index
        respond_to do |format|
          format.html
          format.pdf do
            render_pdf("#{singular_name}_#{Time.now.to_i.to_s}")
          end
          format.csv {
            data = @collection.to_csv({}, params.to_unsafe_h)
            require 'iconv'
            # data = Iconv.new("big5//IGNORE", "utf-8").iconv(data) #remove this if you won't use excel to open csv in traditional Chinese
            send_data data, :filename => "#{singular_name}_#{Time.now.to_i.to_s}.csv",
                      :disposition => 'inline', :type => "text/csv"
          }
        end
      end

      def seacher(override_includes=nil)
        params[:q] ||= {}
        if !params[:q][:created_at_gt].blank?
          params[:q][:created_at_gt] = Time.zone.parse(params[:q][:created_at_gt]).beginning_of_day rescue ""
        end

        if !params[:q][:created_at_lt].blank?
          params[:q][:created_at_lt] = Time.zone.parse(params[:q][:created_at_lt]).end_of_day rescue ""
        end
        base_search = method(:collection).super_method.call
        if params[:checked] == "true"
          result = base_search.includes(override_includes || includes).ransack(params[:q].merge(:id_in => session[session_key]))
        elsif params[:checks]
          result = base_search.includes(override_includes || includes).ransack(params[:q].merge(:id_in => params[:checks].split(",")))
          params[:checks] = nil
        else
          result = base_search.includes(override_includes || includes).ransack(params[:q])
        end
        result
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
        session[session_key] ||= []
        if params[:all].present?
          if params[:all] == "true"
            page_keys = collection.pluck(:id)
            if (page_keys - session[session_key]).empty?
              session[session_key] = (session[session_key] - collection.pluck(:id)).uniq
            else
              session[session_key] = (session[session_key] + collection.pluck(:id)).uniq
            end
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
        head :ok
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
        @object.temp_user_id = spree_current_user.id if spree_current_user && @object.respond_to?(:temp_user_id=)
      end
    end
  end
end
