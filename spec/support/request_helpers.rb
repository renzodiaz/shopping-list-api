module RequestHelpers
  def json_response
    JSON.parse(response.body)
  end

  def auth_header(token)
    { 'Authorization' => "Bearer #{token}" }
  end

  def create_access_token(user, application = nil)
    application ||= create(:oauth_application)

    Doorkeeper::AccessToken.create!(
      resource_owner_id: user.id,
      application: application,
      expires_in: Doorkeeper.configuration.access_token_expires_in,
      scopes: ""
    )
  end
end
