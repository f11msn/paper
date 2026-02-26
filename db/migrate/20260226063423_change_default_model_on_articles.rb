class ChangeDefaultModelOnArticles < ActiveRecord::Migration[8.1]
  def change
    change_column_default :articles, :model, from: "deepseek/deepseek-chat", to: "deepseek/deepseek-v3.2"
  end
end
