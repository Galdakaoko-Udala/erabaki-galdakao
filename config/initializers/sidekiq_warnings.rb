# frozen_string_literal: true

# NOTE: remove this when Decidim is prepared for strict arguments
# This type of errors caused the strict complain:
# Exception: ArgumentError: Job arguments to Decidim::EventPublisherJob must be native JSON types, but 0.9e2 is a BigDecimal.

require "sidekiq"
Sidekiq.strict_args!(false)
