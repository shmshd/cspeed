resource "kubernetes_deployment_v1" "app" {
  metadata {
    name = "node-app"
    labels = {
      app = "node"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "node"
      }
    }

    template {
      metadata {
        labels = {
          app = "node"
        }
      }

      spec {
        container {
          image = var.app_image
          name  = "node-app"
          port {
            container_port = 3000
          }
          env {
            name  = "DB_HOST"
            value = "mysql"
          }
          env {
            name  = "DB_USER"
            value = "cspeed"
          }
          env {
            name  = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql.metadata[0].name
                key  = "password"
              }
            }
          }
          env {
            name  = "DB_NAME"
            value = "todos"
          }
          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name = "node-app"
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.app.metadata.0.labels.app
    }
    session_affinity = "ClientIP"
    port {
      port        = 3000
      target_port = 80
    }

    type = "LoadBalancer"
  }
}