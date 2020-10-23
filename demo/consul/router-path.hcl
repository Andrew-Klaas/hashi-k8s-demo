Kind = "service-router"
Name = "go-movies-app-path"
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
]
