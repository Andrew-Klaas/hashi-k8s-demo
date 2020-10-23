Kind = "service-intentions"
Name = "go-movies-favorites-app"
Sources = [
  {
    Name = "go-movies-app"
    Permissions = [
      {
        Action = "allow"
        HTTP {
          PathPrefix = "/getFavorite"
          Methods    = ["GET", "PUT", "POST", "DELETE", "HEAD"]
        }
      },
      {
        Action = "allow"
        HTTP {
          PathPrefix = "/addtoFavorite"
          Methods    = ["GET", "PUT", "POST", "DELETE", "HEAD"]
        }
      },
      {
        Action = "deny"
        HTTP {
          PathPrefix = "/"
          Methods    = ["GET", "PUT", "POST", "DELETE", "HEAD"]
        }
      }
    ]
  }
  # NOTE: a default catch-all based on the default ACL policy will apply to
  # unmatched connections and requests. Typically this will be DENY.
]