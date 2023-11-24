class AddErrorMessage < ActiveRecord::Migration[7.0]
  def change
    add_column :solvers, :error_message, :string
  end
end
