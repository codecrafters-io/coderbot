class AddExplanationMarkdownField < ActiveRecord::Migration[7.0]
  def change
    add_column :autofix_requests, :explanation_markdown, :text
    remove_column :autofix_requests, :final_diff, :text
    add_column :autofix_requests, :changed_files, :jsonb
  end
end
