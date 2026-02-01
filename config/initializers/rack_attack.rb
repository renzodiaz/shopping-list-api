class Rack::Attack
  # Throttle all requests by IP
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  # Throttle login attempts by email
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/api/v1/auth/login" && req.post?
      req.params["email"].presence
    end
  end

  # Throttle registration
  throttle("registrations/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/api/v1/auth/register" && req.post?
      req.ip
    end
  end
end
