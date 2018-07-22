# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170619160400) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "achievables", force: :cascade do |t|
    t.integer  "achievement_id"
    t.integer  "user_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["achievement_id"], name: "index_achievables_on_achievement_id", using: :btree
    t.index ["user_id"], name: "index_achievables_on_user_id", using: :btree
  end

  create_table "achievements", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "reward"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "condition"
    t.string   "category"
  end

  create_table "articles", force: :cascade do |t|
    t.string   "title"
    t.text     "body"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "badges", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.string   "icon"
    t.string   "icon_color"
    t.string   "bg"
    t.string   "bg_color"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "achievement_id"
    t.string   "icon_style"
    t.index ["achievement_id"], name: "index_badges_on_achievement_id", using: :btree
  end

  create_table "champions", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "icon"
    t.integer  "game_id"
    t.index ["game_id"], name: "index_champions_on_game_id", using: :btree
  end

  create_table "chat_rooms", force: :cascade do |t|
    t.integer  "team_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_chat_rooms_on_team_id", using: :btree
  end

  create_table "ckeditor_assets", force: :cascade do |t|
    t.string   "data_file_name",               null: false
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.integer  "assetable_id"
    t.string   "assetable_type",    limit: 30
    t.string   "type",              limit: 30
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.index ["assetable_type", "assetable_id"], name: "idx_ckeditor_assetable", using: :btree
    t.index ["assetable_type", "type", "assetable_id"], name: "idx_ckeditor_assetable_type", using: :btree
  end

  create_table "coaches", force: :cascade do |t|
    t.boolean  "active"
    t.boolean  "teams"
    t.boolean  "solo"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "compositions", force: :cascade do |t|
    t.integer  "team_id"
    t.string   "picks",      default: [],              array: true
    t.string   "bans",       default: [],              array: true
    t.integer  "win",        default: 0
    t.integer  "lose",       default: 0
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.string   "title"
    t.index ["team_id"], name: "index_compositions_on_team_id", using: :btree
  end

  create_table "contacts", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.text     "message"
    t.string   "nickname"
    t.boolean  "read"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "feedbacks", force: :cascade do |t|
    t.integer  "mentorat_id"
    t.integer  "mentor_id"
    t.integer  "knowledge"
    t.integer  "pedagogy"
    t.integer  "behaviour"
    t.decimal  "average"
    t.text     "content"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "user_id"
    t.index ["mentor_id"], name: "index_feedbacks_on_mentor_id", using: :btree
    t.index ["mentorat_id"], name: "index_feedbacks_on_mentorat_id", using: :btree
    t.index ["user_id"], name: "index_feedbacks_on_user_id", using: :btree
  end

  create_table "friendships", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "friend_id"
    t.integer  "status",     default: 0
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["user_id"], name: "index_friendships_on_user_id", using: :btree
  end

  create_table "game_accounts", force: :cascade do |t|
    t.string   "name"
    t.integer  "real_game_id"
    t.boolean  "active"
    t.integer  "mmr"
    t.string   "tier"
    t.string   "division"
    t.string   "p_role"
    t.string   "s_role",                                    array: true
    t.integer  "user_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "activation_code"
    t.boolean  "validated"
    t.integer  "gameplay"
    t.text     "autre"
    t.string   "champions",       default: [],              array: true
    t.integer  "objectifs",       default: [],              array: true
    t.string   "flex_tier"
    t.string   "flex_division"
    t.integer  "flex_mmr"
    t.integer  "game_id"
    t.index ["game_id"], name: "index_game_accounts_on_game_id", using: :btree
  end

  create_table "games", force: :cascade do |t|
    t.string   "title"
    t.integer  "nb_players"
    t.string   "roles",          default: [],                 array: true
    t.boolean  "has_soloq"
    t.boolean  "has_teamq"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.boolean  "adaptable"
    t.string   "character_name"
    t.string   "player_name"
    t.integer  "mentorat_mmr",   default: 0
    t.string   "discord"
    t.boolean  "active",         default: false
    t.boolean  "compositions",   default: false
    t.boolean  "characters",     default: false
    t.string   "discord_eu"
    t.boolean  "compo_bans",     default: false
  end

  create_table "histories", force: :cascade do |t|
    t.datetime "date"
    t.string   "action"
    t.text     "content"
    t.integer  "team_id"
    t.integer  "teaming_id"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_histories_on_team_id", using: :btree
    t.index ["teaming_id"], name: "index_histories_on_teaming_id", using: :btree
    t.index ["user_id"], name: "index_histories_on_user_id", using: :btree
  end

  create_table "invitations", force: :cascade do |t|
    t.integer  "sender_id"
    t.string   "token"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "receiver_id"
    t.string   "action"
    t.string   "role"
    t.integer  "team_id"
    t.text     "content"
    t.integer  "num_role"
    t.index ["team_id"], name: "index_invitations_on_team_id", using: :btree
  end

  create_table "karmas", force: :cascade do |t|
    t.integer  "voter_id"
    t.integer  "voted_id"
    t.integer  "vote"
    t.text     "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mentorats", force: :cascade do |t|
    t.integer  "mentor_id"
    t.integer  "status"
    t.integer  "hours"
    t.integer  "teacher_id"
    t.text     "problem"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.datetime "last_swap"
    t.integer  "game_account_id"
    t.integer  "team_id"
    t.index ["game_account_id"], name: "index_mentorats_on_game_account_id", using: :btree
    t.index ["mentor_id"], name: "index_mentorats_on_mentor_id", using: :btree
    t.index ["team_id"], name: "index_mentorats_on_team_id", using: :btree
  end

  create_table "mentors", force: :cascade do |t|
    t.text     "about"
    t.text     "cours"
    t.string   "suivi",           default: [],                 array: true
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.integer  "week_start",      default: 0,     null: false
    t.integer  "week_end",        default: 0,     null: false
    t.integer  "we_start",        default: 0,     null: false
    t.integer  "we_end",          default: 0,     null: false
    t.boolean  "active"
    t.decimal  "note",            default: "0.0"
    t.integer  "certification"
    t.integer  "game_account_id"
    t.index ["game_account_id"], name: "index_mentors_on_game_account_id", using: :btree
  end

  create_table "messages", force: :cascade do |t|
    t.integer  "chat_room_id"
    t.integer  "user_id"
    t.text     "body"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "team_id"
    t.index ["chat_room_id"], name: "index_messages_on_chat_room_id", using: :btree
    t.index ["team_id"], name: "index_messages_on_team_id", using: :btree
    t.index ["user_id"], name: "index_messages_on_user_id", using: :btree
  end

  create_table "notes", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "team_id"
    t.integer  "composition_id"
    t.text     "body"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["composition_id"], name: "index_notes_on_composition_id", using: :btree
    t.index ["team_id"], name: "index_notes_on_team_id", using: :btree
    t.index ["user_id"], name: "index_notes_on_user_id", using: :btree
  end

  create_table "notifications", force: :cascade do |t|
    t.integer  "recepteur_id"
    t.integer  "emetteur_id"
    t.datetime "read_at"
    t.string   "action"
    t.integer  "notifiable_id"
    t.string   "notifiable_type"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "category"
    t.string   "content"
  end

  create_table "plannings", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "team_id"
    t.integer  "lun"
    t.integer  "mar"
    t.integer  "mer"
    t.integer  "jeu"
    t.integer  "ven"
    t.integer  "sam"
    t.integer  "dim"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_plannings_on_team_id", using: :btree
    t.index ["user_id"], name: "index_plannings_on_user_id", using: :btree
  end

  create_table "pollings", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "poll_id"
    t.integer  "vote"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["poll_id"], name: "index_pollings_on_poll_id", using: :btree
    t.index ["user_id"], name: "index_pollings_on_user_id", using: :btree
  end

  create_table "polls", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "game_id"
    t.string   "title"
    t.text     "body"
    t.string   "choices",    default: [],                 array: true
    t.boolean  "featured",   default: false
    t.integer  "result",     default: 0
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "language"
    t.index ["game_id"], name: "index_polls_on_game_id", using: :btree
    t.index ["user_id"], name: "index_polls_on_user_id", using: :btree
  end

  create_table "premades", force: :cascade do |t|
    t.integer  "user1"
    t.integer  "user2"
    t.integer  "user3"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "seances", force: :cascade do |t|
    t.integer  "mentorat_id"
    t.integer  "mentor_id"
    t.string   "title"
    t.text     "content"
    t.text     "advice"
    t.datetime "date"
    t.integer  "duration"
    t.integer  "status"
    t.integer  "mmr"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.time     "hour"
    t.index ["mentor_id"], name: "index_seances_on_mentor_id", using: :btree
    t.index ["mentorat_id"], name: "index_seances_on_mentorat_id", using: :btree
  end

  create_table "search_suggestions", force: :cascade do |t|
    t.string   "term"
    t.integer  "popularity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shortened_urls", force: :cascade do |t|
    t.integer  "owner_id"
    t.string   "owner_type", limit: 20
    t.text     "url",                               null: false
    t.string   "unique_key", limit: 10,             null: false
    t.string   "label"
    t.string   "string"
    t.integer  "use_count",             default: 0, null: false
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "category"
    t.index ["label"], name: "index_shortened_urls_on_label", using: :btree
    t.index ["owner_id", "owner_type"], name: "index_shortened_urls_on_owner_id_and_owner_type", using: :btree
    t.index ["unique_key"], name: "index_shortened_urls_on_unique_key", unique: true, using: :btree
    t.index ["url"], name: "index_shortened_urls_on_url", using: :btree
  end

  create_table "subscription_plans", force: :cascade do |t|
    t.string   "title"
    t.text     "content"
    t.decimal  "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "role"
    t.integer  "duration"
    t.boolean  "active"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "user_id"
    t.boolean  "active"
    t.date     "end_date"
    t.decimal  "price"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "subscription_plan_id"
    t.string   "token"
    t.string   "payer_id"
    t.string   "payment_method"
    t.decimal  "renewal_price"
    t.integer  "renewal_duration"
    t.index ["subscription_plan_id"], name: "index_subscriptions_on_subscription_plan_id", using: :btree
    t.index ["user_id"], name: "index_subscriptions_on_user_id", using: :btree
  end

  create_table "team_applications", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "team_id"
    t.text     "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "role"
    t.integer  "num_role"
    t.index ["team_id"], name: "index_team_applications_on_team_id", using: :btree
    t.index ["user_id"], name: "index_team_applications_on_user_id", using: :btree
  end

  create_table "teamings", force: :cascade do |t|
    t.integer  "team_id"
    t.integer  "user_id"
    t.string   "role"
    t.date     "end_date"
    t.boolean  "active"
    t.boolean  "captain"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "reason"
    t.integer  "swap"
    t.integer  "num_role"
    t.boolean  "advices",    default: false
    t.index ["team_id"], name: "index_teamings_on_team_id", using: :btree
    t.index ["user_id"], name: "index_teamings_on_user_id", using: :btree
  end

  create_table "teams", force: :cascade do |t|
    t.string   "name",       default: "", null: false
    t.date     "start_date"
    t.date     "end_date"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "u_count",    default: 0
    t.string   "discord"
    t.integer  "game_id"
    t.integer  "players",                              array: true
    t.string   "roles",                                array: true
    t.index ["game_id"], name: "index_teams_on_game_id", using: :btree
  end

  create_table "tournaments", force: :cascade do |t|
    t.string   "name"
    t.string   "owner"
    t.string   "logo"
    t.string   "website"
    t.string   "vocal"
    t.string   "registration"
    t.integer  "mmr"
    t.integer  "frequency"
    t.integer  "day"
    t.text     "rules"
    t.text     "prizes"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "map"
    t.integer  "battle"
    t.date     "date"
    t.time     "hour"
    t.integer  "game_id"
    t.index ["game_id"], name: "index_tournaments_on_game_id", using: :btree
  end

  create_table "urls", force: :cascade do |t|
    t.string   "original"
    t.string   "short"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_urls_on_user_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "user_name"
    t.string   "first_name"
    t.string   "last_name"
    t.date     "birth_date"
    t.string   "provider"
    t.string   "uid"
    t.string   "role"
    t.integer  "state",                  default: 0,  null: false
    t.integer  "week_start",             default: 0,  null: false
    t.integer  "week_end",               default: 0,  null: false
    t.integer  "we_start",               default: 0,  null: false
    t.integer  "we_end",                 default: 0,  null: false
    t.string   "date_search"
    t.string   "avatar"
    t.string   "address"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "horaire"
    t.string   "skype"
    t.integer  "parrain"
    t.string   "icon"
    t.boolean  "unsubscribe"
    t.text     "admin_note"
    t.string   "discord"
    t.integer  "status",                 default: 0
    t.string   "country"
    t.string   "lang_p"
    t.string   "lang_s",                 default: [],              array: true
    t.string   "language"
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  create_table "votes", force: :cascade do |t|
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "team_id"
    t.integer  "votable_id"
    t.string   "votable_type"
    t.string   "action"
    t.integer  "counter"
    t.integer  "votes"
    t.boolean  "result"
    t.boolean  "has_voted",                 array: true
    t.index ["team_id"], name: "index_votes_on_team_id", using: :btree
  end

  create_table "wallet_histories", force: :cascade do |t|
    t.integer  "amount",      default: 0
    t.string   "action"
    t.string   "category"
    t.integer  "wallet_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.string   "paysafecard"
    t.boolean  "validation"
    t.index ["wallet_id"], name: "index_wallet_histories_on_wallet_id", using: :btree
  end

  create_table "wallets", force: :cascade do |t|
    t.integer  "balance",    default: 0
    t.integer  "user_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["user_id"], name: "index_wallets_on_user_id", using: :btree
  end

  create_table "whitelists", force: :cascade do |t|
    t.string   "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "achievables", "achievements"
  add_foreign_key "achievables", "users"
  add_foreign_key "badges", "achievements"
  add_foreign_key "champions", "games"
  add_foreign_key "chat_rooms", "teams"
  add_foreign_key "compositions", "teams"
  add_foreign_key "feedbacks", "mentorats"
  add_foreign_key "feedbacks", "mentors"
  add_foreign_key "feedbacks", "users"
  add_foreign_key "friendships", "users"
  add_foreign_key "histories", "teamings"
  add_foreign_key "histories", "teams"
  add_foreign_key "histories", "users"
  add_foreign_key "invitations", "teams"
  add_foreign_key "mentorats", "game_accounts"
  add_foreign_key "mentorats", "mentors"
  add_foreign_key "mentorats", "teams"
  add_foreign_key "mentors", "game_accounts"
  add_foreign_key "messages", "chat_rooms"
  add_foreign_key "messages", "teams"
  add_foreign_key "messages", "users"
  add_foreign_key "notes", "compositions"
  add_foreign_key "notes", "teams"
  add_foreign_key "notes", "users"
  add_foreign_key "plannings", "teams"
  add_foreign_key "plannings", "users"
  add_foreign_key "pollings", "polls"
  add_foreign_key "pollings", "users"
  add_foreign_key "polls", "games"
  add_foreign_key "polls", "users"
  add_foreign_key "seances", "mentorats"
  add_foreign_key "seances", "mentors"
  add_foreign_key "subscriptions", "subscription_plans"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "team_applications", "teams"
  add_foreign_key "team_applications", "users"
  add_foreign_key "teamings", "teams"
  add_foreign_key "teamings", "users"
  add_foreign_key "tournaments", "games"
  add_foreign_key "urls", "users"
  add_foreign_key "wallet_histories", "wallets"
  add_foreign_key "wallets", "users"
end
