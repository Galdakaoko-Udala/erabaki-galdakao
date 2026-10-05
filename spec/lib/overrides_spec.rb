# frozen_string_literal: true

require "rails_helper"

# We make sure that the checksum of the file overriden is the same
# as the expected. If this test fails, it means that the overriden
# file should be updated to match any change/bug fix introduced in the core
checksums = [
  {
    package: "decidim-core",
    files: {
      "/app/views/layouts/decidim/header/_main.html.erb" => "2808459045fd14b7f8d689fbbd6dfa4e",
      "/app/views/decidim/devise/shared/_omniauth_buttons.html.erb" => "688a13e36af349a91e37b04c6caaa3a9"
    }
  },
  {
    package: "decidim-proposals",
    files: {
      "/lib/decidim/proposals/proposal_serializer.rb" => "eadfc45fe2e1388d579a7ffa2f87c478"
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
