class AddAutofixRequestModel < ActiveRecord::Migration[7.0]
  def change
    rename_table :solvers, :autofix_requests
  end
end
