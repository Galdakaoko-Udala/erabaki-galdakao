# frozen_string_literal: true

# This migration comes from decidim_meetings (originally 20180801150031)
# This file has been modified by `decidim upgrade:migrations` task on 2025-10-10 11:37:27 UTC
class AddRegistrationFormEnabledToDecidimMeetings < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_meetings_meetings, :registration_form_enabled, :boolean, default: false
  end
end
