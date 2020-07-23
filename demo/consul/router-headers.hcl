Kind = "service-router"
Name = "go-movies-app"
Routes = [
  {
    Match {
      HTTP {
        Header = [
          {
            Name  = "x-debug"
            Exact = "1"
          },
        ]
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
        header = [
          {
            Name  = "x-debug"
            Exact = "2"
          },
        ]
      }
    }
    Destination {
      Service       = "go-movies-app"
      ServiceSubset = "v2"
    }
  },
  # NOTE: a default catch-all will send unmatched traffic to "web"
]
