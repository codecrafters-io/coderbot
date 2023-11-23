class AddSolverStats < ActiveRecord::Migration[7.0]
  def change
    add_column :solvers, :steps_count, :integer
    add_column :solvers, :duration_ms, :integer
    add_column :solvers, :final_diff, :text
  end
end
