kind = "service-splitter"
name = "go-movies-app"
splits = [
  {
    weight         = 50
    service_subset = "v1"
  },
  {
    weight         = 50
    service_subset = "v2"
  },
]