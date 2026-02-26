class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :topic, null: false
      t.string :rubric, null: false
      t.text :system_prompt, null: false
      t.text :content
      t.string :model, null: false, default: "deepseek/deepseek-chat"
      t.float :temperature, null: false, default: 0.7
      t.integer :max_tokens, null: false, default: 4096
      t.string :status, null: false, default: "pending"
      t.json :api_log
      t.json :tool_calls_log

      t.timestamps
    end
  end
end
