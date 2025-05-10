class CreateSupportArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :support_articles do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :title
      t.text :content

      t.timestamps
    end
  end
end
