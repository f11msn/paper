class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.string :title
      t.text :system_prompt

      t.timestamps
    end
  end
end
