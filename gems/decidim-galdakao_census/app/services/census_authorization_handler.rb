# frozen_string_literal: true
require "digest/md5"


class CensusAuthorizationHandler < Decidim::AuthorizationHandler
  attribute :document_number, String
  attribute :date_of_birth, Date

  validates :date_of_birth, presence: true
  validates :document_number,
            presence: true,
            format: { with: /\A[a-zA-Z]?\d{7,8}[a-zA-Z]\z/ }

  validate :check_lockout
  validate :document_number_valid

  def metadata
    super.merge(
      date_of_birth: date_of_birth&.strftime("%Y-%m-%d"),
      street:        response&.xpath("//autenticarResult/calle")&.text&.strip,
      street_number: response&.xpath("//autenticarResult/portal")&.text&.strip&.to_i
    )
  end

  def unique_id
    Digest::MD5.hexdigest("#{document_number&.upcase}-#{Rails.application.secret_key_base}")
  end

  private

  def lockout_manager
    @lockout_manager ||= Decidim::GaldakaoCensus::LockoutManager.new(user)
  end

  def check_lockout
    return unless user.present?
    message = lockout_manager.check_lockout
    errors.add(:base, message) if message.present?
  end

  def document_number_valid
    return if errors.any?

    soap_response = response

    if soap_response.nil?
      errors.add(:base, I18n.t("census_authorization_handler.service_unavailable"))
      return
    end

    result = soap_response.at_xpath("//autenticarResult/autenticarResult")&.text

    if result == "true"
      lockout_manager.register_success
    else
      message = lockout_manager.register_failed_attempt
      errors.add(:base, message)
    end
  end

  def sanitized_date_of_birth
    date_of_birth&.strftime("%Y-%m-%d")
  end

  def sanitized_document_number
    document_number.to_s[/\d+/]
  end

  def sanitized_document_letter
    document_number.to_s[/[a-zA-Z]\z/]&.upcase
  end

  def response
    return @response if defined?(@response)

    ws = GaldakaoWebservice.new("autenticar")
    ws.body = <<~XML
      <tns:dni>#{document_number&.upcase}</tns:dni>
      <tns:fecha_nacimiento>#{sanitized_date_of_birth}</tns:fecha_nacimiento>
    XML

    @response = ws.response
  end
end