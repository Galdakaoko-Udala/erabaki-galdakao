# frozen_string_literal: true

# This migration comes from decidim (originally 20191118123154)
# This file has been modified by `decidim upgrade:migrations` task on 2025-10-10 11:37:27 UTC
class AddAdminTermsOfUseBodyFieldToOrganization < ActiveRecord::Migration[5.2]
  def change
    change_table :decidim_organizations do |t|
      t.jsonb :admin_terms_of_use_body, null: true
    end
  end
end
