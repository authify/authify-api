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

ActiveRecord::Schema.define(version: 20170204001405) do

  create_table "api_keys", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.string   "access_key"
    t.text     "secret_key_digest", limit: 65535
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.index ["access_key"], name: "index_api_keys_on_access_key", using: :btree
    t.index ["user_id"], name: "index_api_keys_on_user_id", using: :btree
  end

  create_table "groups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "organization_id"
    t.string   "name"
    t.text     "description",     limit: 65535
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.index ["name"], name: "index_groups_on_name", using: :btree
    t.index ["organization_id"], name: "index_groups_on_organization_id", using: :btree
  end

  create_table "groups_users", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "group_id"
    t.integer "user_id"
    t.index ["group_id"], name: "index_groups_users_on_group_id", using: :btree
    t.index ["user_id"], name: "index_groups_users_on_user_id", using: :btree
  end

  create_table "identities", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider"], name: "index_identities_on_provider", using: :btree
    t.index ["uid"], name: "index_identities_on_uid", using: :btree
    t.index ["user_id"], name: "index_identities_on_user_id", using: :btree
  end

  create_table "organization_memberships", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "organization_id"
    t.integer "user_id"
    t.boolean "admin",           default: false
    t.index ["admin"], name: "index_organization_memberships_on_admin", using: :btree
    t.index ["organization_id"], name: "index_organization_memberships_on_organization_id", using: :btree
    t.index ["user_id"], name: "index_organization_memberships_on_user_id", using: :btree
  end

  create_table "organizations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "public_email"
    t.string   "gravatar_email"
    t.string   "billing_email"
    t.text     "description",    limit: 65535
    t.string   "url"
    t.string   "location"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.index ["name"], name: "index_organizations_on_name", using: :btree
  end

  create_table "trusted_delegates", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "access_key"
    t.text     "secret_key_digest", limit: 65535
    t.text     "description",       limit: 65535
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.index ["access_key"], name: "index_trusted_delegates_on_access_key", using: :btree
    t.index ["name"], name: "index_trusted_delegates_on_name", using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "email"
    t.text     "password_digest", limit: 65535
    t.string   "full_name"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.index ["email"], name: "index_users_on_email", using: :btree
  end

end
