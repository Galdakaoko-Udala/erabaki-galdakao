# frozen_string_literal: true

require "rails_helper"

# We make sure that the checksum of the file overriden is the same
# as the expected. If this test fails, it means that the overriden
# file should be updated to match any change/bug fix introduced in the core
checksums = [
  {
    package: "decidim-admin",
    files: {
      # layouts
      "/app/views/layouts/decidim/admin/_header.html.erb" => "6e5893f735d2097f0e55e8b6666cb201"
    }
  },
  {
    package: "decidim-verifications",
    files: {
      # lib/decidim/galdakao_census/overrides/managed_user_error_event.rb
      "/app/events/decidim/verifications/managed_user_error_event.rb" => "ef08dfd436d2296f9102c63a8ebb9af5"
    }
  }
]

describe "Overriden files", type: :view do
  checksums.each do |item|
    spec = Gem::Specification.find_by_name(item[:package]) # rubocop:disable RSpec/LeakyLocalVariable
    item[:files].each do |file, signature|
      it "#{spec.gem_dir}#{file} matches checksum" do
        expect(md5("#{spec.gem_dir}#{file}")).to eq(signature)
      end
    end
  end

  private

  def md5(file)
    Digest::MD5.hexdigest(File.read(file))
  end
end
