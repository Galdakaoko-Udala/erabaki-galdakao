# frozen_string_literal: true

# This migration comes from decidim (originally 20180123125308)
# This file has been modified by `decidim upgrade:migrations` task on 2025-10-10 11:37:27 UTC
class AddEnableOmnipresentBannerToDecidimOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_organizations, :enable_omnipresent_banner, :boolean, null: false, default: false
  end
end
