kind = "service-splitter"
name = "emojify-website"
splits = [
  {
    weight         = 10
    service_subset = "v1"
  },
  {
    weight         = 90
    service_subset = "v2"
  },
]