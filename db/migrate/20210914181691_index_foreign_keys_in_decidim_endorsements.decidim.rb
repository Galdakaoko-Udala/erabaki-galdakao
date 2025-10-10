# frozen_string_literal: true

# This migration comes from decidim (originally 20200320105919)
# This file has been modified by `decidim upgrade:migrations` task on 2025-10-10 11:37:27 UTC
class IndexForeignKeysInDecidimEndorsements < ActiveRecord::Migration[5.2]
  def change
    add_index :decidim_endorsements, :decidim_user_group_id
  end
end
