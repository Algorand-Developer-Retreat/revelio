class CreateContracts < ActiveRecord::Migration[8.0]
  def change
    create_table :contracts do |t|
      t.string :name
      t.float :version
      t.integer :app_id
      t.bigint :round_valid_from
      t.string :address
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
