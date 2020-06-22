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
  }
]