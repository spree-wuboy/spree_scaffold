Spree::Core::Engine.routes.draw do
  get 'tinymce/insert', :to => 'tinymce#insert'
  get 'tinymce/insert_url', :to => 'tinymce#insert_url'
  post 'tinymce/upload', :to => 'tinymce#upload'
  namespace :admin do
    resources :simple_images do
      post :publish, :to => :publish, :as => :image_publish
    end
  end
end