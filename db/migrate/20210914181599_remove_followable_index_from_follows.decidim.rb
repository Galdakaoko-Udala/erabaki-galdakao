# frozen_string_literal: true

# This migration comes from decidim (originally 20170914075721)
# This file has been modified by `decidim upgrade:migrations` task on 2025-10-10 11:37:27 UTC
class RemoveFollowableIndexFromFollows < ActiveRecord::Migration[5.1]
  def change
    remove_index :decidim_follows, [:decidim_followable_id, :decidim_followable_type]
  end
end
