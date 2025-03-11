class AddParentIdToContracts < ActiveRecord::Migration[8.0]
  def change
    add_reference :contracts, :parent, foreign_key: { to_table: :contracts }
    change_column_null :contracts, :version, false
    change_column_default :contracts, :version, 0
  end
end
