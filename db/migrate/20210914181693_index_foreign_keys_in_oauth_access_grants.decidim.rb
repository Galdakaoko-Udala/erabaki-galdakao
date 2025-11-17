# frozen_string_literal: true

# This migration comes from decidim (originally 20200320105927)
# This file has been modified by `decidim upgrade:migrations` task on 2025-10-10 11:37:27 UTC
class IndexForeignKeysInOAuthAccessGrants < ActiveRecord::Migration[5.2]
  def change
    add_index :oauth_access_grants, :resource_owner_id
  end
end
