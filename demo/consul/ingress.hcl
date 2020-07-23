Kind = "ingress-gateway"
Name = "ingress-gateway"
Listeners = [
  {
    Port = 5000
    Protocol = "tcp"
    Services = [
      {
        Name = "k8s-transit-app"
      }
    ]
  },
  {
    Port = 8080
    Protocol = "http"
    Services = [
      {
        Name = "go-movies-app"
      }
    ]
  }
]