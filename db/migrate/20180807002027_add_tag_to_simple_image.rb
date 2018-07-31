class AddTagToSimpleImage < ActiveRecord::Migration[5.1]
  def change
    add_column  :spree_simple_images, :tag, :string
    add_column  :spree_simple_images, :link_url, :string
    add_column  :spree_simple_images, :position, :integer
    add_index :spree_simple_images, :tag
  end
end
