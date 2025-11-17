# frozen_string_literal: true

# This migration comes from decidim (originally 20170128140553)
# This file has been modified by `decidim upgrade:migrations` task on 2025-10-10 11:37:26 UTC
class AddTimestampsToIdentities < ActiveRecord::Migration[5.0]
  def change
    add_timestamps :decidim_identities
  end
end
