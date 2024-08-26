locals {
  kubernetes_ports = [
    "6443",   # API Server
    "2379",   # etcd
    "2380",   # etcd peer communication
    "10250",  # Kubelet
    "10255",  # Kubelet read-only API
    "10252",  # kube-controller-manager
    "10251",  # kube-scheduler
    "10049",  # kube-proxy
    "30000-32767", # NodePort services
    "80",     # Ingress (HTTP)
    "443",    # Ingress (HTTPS)
    "8080",   # Metrics server
    "10443"   # microk8s
  ]
}