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

ActiveRecord::Schema[8.0].define(version: 2025_10_23_141458) do
  create_table "actions", force: :cascade do |t|
    t.integer "player_id", null: false
    t.string "action_type"
    t.integer "target_x"
    t.integer "target_y"
    t.datetime "completes_at"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_actions_on_player_id"
  end

  create_table "examples", force: :cascade do |t|
    t.string "name"
    t.string "category"
    t.string "status"
    t.text "description"
    t.integer "priority"
    t.decimal "score"
    t.integer "complexity"
    t.integer "speed"
    t.integer "quality"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "factions", force: :cascade do |t|
    t.string "name"
    t.string "color"
    t.integer "total_power"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "game_states", force: :cascade do |t|
    t.boolean "running"
    t.integer "winner_faction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "player_positions", force: :cascade do |t|
    t.integer "player_id", null: false
    t.integer "territory_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_player_positions_on_player_id"
    t.index ["territory_id"], name: "index_player_positions_on_territory_id"
  end

  create_table "players", force: :cascade do |t|
    t.integer "faction_id", null: false
    t.string "name"
    t.boolean "is_bot"
    t.integer "resources"
    t.integer "power_level"
    t.datetime "last_active_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_territory_id"
    t.index ["faction_id"], name: "index_players_on_faction_id"
  end

  create_table "territories", force: :cascade do |t|
    t.integer "x"
    t.integer "y"
    t.integer "faction_id"
    t.integer "player_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_rally_point", default: false, null: false
    t.index ["faction_id"], name: "index_territories_on_faction_id"
  end

  add_foreign_key "actions", "players"
  add_foreign_key "player_positions", "players"
  add_foreign_key "player_positions", "territories"
  add_foreign_key "players", "factions"
  add_foreign_key "territories", "factions"
end
