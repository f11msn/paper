# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_26_063423) do
  create_table "articles", force: :cascade do |t|
    t.json "api_log"
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "max_tokens", default: 4096, null: false
    t.string "model", default: "deepseek/deepseek-v3.2", null: false
    t.string "rubric", null: false
    t.string "status", default: "pending", null: false
    t.text "system_prompt", null: false
    t.float "temperature", default: 0.7, null: false
    t.json "tool_calls_log"
    t.string "topic", null: false
    t.datetime "updated_at", null: false
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "system_prompt"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.integer "conversation_id", null: false
    t.datetime "created_at", null: false
    t.string "role"
    t.string "tool_call_id"
    t.json "tool_calls"
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
  end

  add_foreign_key "messages", "conversations"
end
