Kind = "service-router"
Name = "go-movies-app"
Routes = [
  {
    Match {
      HTTP {
        PathPrefix  = "/v1"
      }
    }
    Destination {
      Service       = "go-movies-app"
      ServiceSubset = "v1"
    }
  },
  {
    Match {
      HTTP {
        PathPrefix  = "/v2"
      }
    }
    Destination {
      Service       = "go-movies-app"
      ServiceSubset = "v2"
    }
  },
  # NOTE: a default catch-all will send unmatched traffic to "web"
]
