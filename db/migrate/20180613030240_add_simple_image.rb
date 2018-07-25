class AddSimpleImage < ActiveRecord::Migration[5.1]
  def change
    create_table :spree_simple_images do |t|
      t.integer :attachment_width
      t.integer :attachment_height
      t.integer :attachment_file_size
      t.string :attachment_content_type
      t.string :attachment_file_name
      t.datetime :attachment_updated_at
      t.string :alt
      t.string :checksum
      t.timestamp
    end
  end
end
