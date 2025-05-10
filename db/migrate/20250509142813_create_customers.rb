class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.string :name
      t.text :connection_string

      t.timestamps
    end
  end
end
