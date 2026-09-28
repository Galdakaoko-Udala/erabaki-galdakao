# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Overrides
      # Changes the notification sent to admins when a participant tries to verify with data
      # already used by another participant: it only links to the verification conflicts list,
      # without the links to the profiles nor the name of the managed user.
      #
      # The methods are replaced (not prepended) on purpose: `super` in default_i18n_options must
      # skip the original method, which adds the managed user data, and call SimpleEvent's.
      # The texts are overridden in decidim.events.verifications.verify_with_managed_user.
      # spec/lib/overrides_spec.rb checks that the original class has not changed.
      module ManagedUserErrorEvent
        extend ActiveSupport::Concern

        included do
          def resource_path
            nil
          end

          def resource_url
            nil
          end

          def resource_title
            nil
          end

          def default_i18n_options
            super.merge({ conflicts_path: decidim_admin.conflicts_path,
                          conflicts_url: decidim_admin.conflicts_url })
          end

          private

          def decidim_admin
            @decidim_admin ||= Decidim::EngineRouter.new("decidim_admin", { host: organization.host })
          end

          def organization
            resource.current_user.organization
          end
        end
      end
    end
  end
end
