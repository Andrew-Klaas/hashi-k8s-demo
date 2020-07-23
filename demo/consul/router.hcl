kind = "service-router"
name = "go-movies-app"
routes = [
  {
    match {
      http {
        query_param = [
          {
            name  = "x-version"
            exact = "1"
          },
        ]
      }
    }
    destination {
      service        = "go-movies-app"
      service_subset = "v1"
    }
  },
  {
    match {
      http {
        query_param = [
          {
            name  = "x-version"
            exact = "2"
          },
        ]
      }
    }
    destination {
      service        = "go-movies-app"
      service_subset = "v2"
    }
  }
]