# frozen_string_literal: true

require "digest"

module Decidim
  module GaldakaoCensus
    class CensusAuthorizationHandler < Decidim::AuthorizationHandler
      # DNI (8 digits) or NIE (X/Y/Z + 7 digits), plus the old K/L/M documents,
      # followed by the control letter. A DNI without its leading zero is also accepted.
      DOCUMENT_FORMAT = /\A[XYZKLM]?\d{7,8}[A-Z]\z/
      CONTROL_LETTERS = "TRWAGMYFPDXBNJZSQVHLCKE"
      NIE_PREFIXES = { "X" => "0", "Y" => "1", "Z" => "2" }.freeze

      attribute :document_number, String
      attribute :date_of_birth, Date

      validates :date_of_birth, presence: true
      validates :document_number, presence: true, format: { with: DOCUMENT_FORMAT }
      validate :document_control_letter

      validate :check_lockout
      validate :document_number_valid

      def document_number
        super.to_s.strip.upcase.presence
      end

      def metadata
        super.merge(
          date_of_birth: formatted_date_of_birth,
          street: xpath_text("//autenticarResult/calle").presence,
          street_number:
        )
      end

      def unique_id
        Digest::SHA256.hexdigest("#{document_number}-#{Rails.application.secret_key_base}")
      end

      private

      # nil when the register returns no portal (or one without digits, e.g. "s/n"),
      # so that a missing portal is never treated as number 0
      def street_number
        xpath_text("//autenticarResult/portal").to_s[/\d+/]&.to_i
      end

      def xpath_text(node)
        return unless response

        response.xpath(node)&.text&.strip
      end

      # Checked locally so that a typo does not call the register nor count as a failed attempt
      def document_control_letter
        return if errors.include?(:document_number)

        prefix = document_number[/\A[A-Z](?=\d)/]
        digits = document_number[/\d+/]
        number = "#{NIE_PREFIXES.fetch(prefix, "")}#{digits}".to_i

        errors.add(:document_number, :invalid) unless document_number[-1] == CONTROL_LETTERS[number % 23]
      end

      def lockout_manager
        @lockout_manager ||= LockoutManager.new(user)
      end

      def check_lockout
        return if user.blank?

        message = lockout_manager.check_lockout
        errors.add(:base, message) if message.present?
      end

      def document_number_valid
        return if errors.any?

        if response.nil?
          errors.add(:base, I18n.t("decidim.authorization_handlers.census_authorization_handler.service_unavailable"))
          return
        end

        if response.at_xpath("//autenticarResult/autenticarResult")&.text == "true"
          lockout_manager.register_success
        else
          errors.add(:base, lockout_manager.register_failed_attempt)
        end
      end

      def formatted_date_of_birth
        date_of_birth&.strftime("%Y-%m-%d")
      end

      def response
        return @response if defined?(@response)

        webservice = Webservice.new(Webservice::AUTHENTICATE)
        webservice.body = <<~XML
          <tns:dni>#{document_number.to_s.encode(xml: :text)}</tns:dni>
          <tns:fecha_nacimiento>#{formatted_date_of_birth}</tns:fecha_nacimiento>
        XML

        @response = webservice.response
      end
    end
  end
end
