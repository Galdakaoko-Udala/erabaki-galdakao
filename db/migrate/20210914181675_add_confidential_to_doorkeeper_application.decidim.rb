# frozen_string_literal: true

# This migration comes from decidim (originally 20190618075906)
# This file has been modified by `decidim upgrade:migrations` task on 2025-10-10 11:37:27 UTC
class AddConfidentialToDoorkeeperApplication < ActiveRecord::Migration[5.2]
  def change
    add_column(
      :oauth_applications,
      :confidential,
      :boolean,
      null: false,
      default: true # maintaining backwards compatibility: require secrets
    )
  end
end
