variable "mysql_password" {
}

variable "mysql_version" {
  default = "8.3.0"
}

resource "kubernetes_service" "mysql" {
  metadata {
    name   = "mysql"
    labels = {
      app = "mysql"
    }
  }
  spec {
    port {
      port        = 3306
      target_port = 3306
    }
    selector = {
      app = "mysql"
    }
    cluster_ip = "None"
  }
}

resource "kubernetes_persistent_volume_claim" "mysql" {
  metadata {
    name   = "mysql-pv-claim"
    labels = {
      app = "mysql"
    }
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

resource "kubernetes_secret" "mysql" {
  metadata {
    name = "mysql-pass"
  }

  data = {
    password = var.mysql_password
  }
}

resource "kubernetes_deployment_v1" "mysql" {
  metadata {
    name   = "mysql"
    labels = {
      app = "mysql"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "mysql"
      }
    }
    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }
      spec {
        container {
          image = "mysql:${var.mysql_version}"
          name  = "mysql"
          env {
            name  = "MYSQL_RANDOM_ROOT_PASSWORD"
            value = "1"
          }
          env {
            name  = "MYSQL_USER"
            value = "cspeed"
          }
          env {
            name = "MYSQL_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql.metadata[0].name
                key  = "password"
              }
            }
          }
          env {
            name  = "MYSQL_DATABASE"
            value = "todos"
          }
          port {
            container_port = 3306
            name           = "mysql"
          }
          resources {
            limits = {
              cpu    = "200m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "50Mi"
            }
          }
          volume_mount {
            name       = "mysql-persistent-storage"
            mount_path = "/var/lib/mysql"
          }
          volume_mount {
            name       = "mysql-initdb"
            mount_path = "/docker-entrypoint-initdb.d"
          }
        }
        volume {
          name = "mysql-persistent-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mysql.metadata[0].name
          }
        }
        volume {
          name = "mysql-initdb"
          config_map {
            name = "mysql-init"
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map" "mysql" {
  metadata {
    name = "mysql-init"
  }

  data = {
    "initdb.sql" = file("${path.module}/initdb.sql")
  }
}