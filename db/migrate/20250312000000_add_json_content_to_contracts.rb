class AddJsonContentToContracts < ActiveRecord::Migration[8.0]
  def change
    add_column :contracts, :arc56, :json
  end
end 