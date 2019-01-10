class TitoWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_webhook_token

  def registration_completed
    text = params[:tickets].map do |ticket|
      <<-END.gsub(/^\s+\|/, '')
        |> Y'all! *#{ticket[:name]}* (#{ticket[:email]}) bought a #{ticket[:release_title]} and is gonna #ComeCampWithUs :tent:
        |> #{ticket[:admin_url]}
      END
    end.join("\n")

    logger.info text

    uri = URI.parse(ENV.fetch("SLACK_WEBHOOK_URL"))
    payload = { text: text }

    http_client = Net::HTTP.new(uri.host, uri.port)
    http_client.use_ssl = true
    slack_request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
    slack_request.body = payload.to_json
    slack_response = http_client.request(slack_request)

    head slack_response.code
  end

  private

  def verify_webhook_token
    hash = Base64.encode64(
      OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'),
      ENV.fetch("TITO_WEBHOOK_SECURITY_TOKEN"),
    request.raw_post)).strip
    if hash != request.headers["Tito-Signature"]
      head 403
    end
  end
end
