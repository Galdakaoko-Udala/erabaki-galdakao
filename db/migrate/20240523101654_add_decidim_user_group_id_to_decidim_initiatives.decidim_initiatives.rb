# frozen_string_literal: true

# This migration comes from decidim_initiatives (originally 20170927131354)
# This file has been modified by `decidim upgrade:migrations` task on 2025-10-10 11:37:27 UTC
class AddDecidimUserGroupIdToDecidimInitiatives < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_initiatives,
               :decidim_user_group_id, :integer, index: true
  end
end
