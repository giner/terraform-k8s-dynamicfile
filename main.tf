locals {
  updater_script = <<-EOT
    set -eu

    period=$UPDATER_PERIOD
    command=$UPDATER_COMMAND

    html_dir=/usr/share/nginx/html
    index_file="$html_dir/index.html"

    while true; do
      start_time=$(date +%s)
      exit_code=0

      if /bin/sh -c "$command" > "$index_file.new"; then
        mv "$index_file.new" "$index_file"
      else
        exit_code=$?
        echo "ERROR: Failed to update data by running $command"
      fi

      end_time=$(date +%s)
      sleep "$((period - (end_time - start_time)))"

      if [ "$exit_code" -ne 0 ]; then
        exit $exit_code
      fi
    done
  EOT
}

resource "kubernetes_config_map_v1" "config" {
  metadata {
    name      = "${var.name}-config"
    namespace = var.namespace
  }

  data = {
    "staticfile.conf" = <<-EOF
      add_header Cache-Control no-cache;

      gzip on;
      gzip_types ${var.content_type};

      types {
          ${var.content_type} html;
      }
    EOF
  }
}

resource "kubernetes_service_v1" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    selector = {
      app = var.name
    }

    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_deployment_v1" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.name
      }
    }

    template {
      metadata {
        labels = {
          app = var.name
        }
      }

      spec {
        container {
          name  = "nginx"
          image = var.nginx_image

          port {
            container_port = 80
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/nginx/conf.d/staticfile.conf"
            sub_path   = "staticfile.conf"
          }

          volume_mount {
            name       = "content"
            mount_path = "/usr/share/nginx/html"
            read_only  = true
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }

            requests = {
              cpu    = "0"
              memory = "32Mi"
            }
          }
        }

        container {
          name  = "updater"
          image = coalesce(var.updater_image, var.nginx_image)

          command = ["/bin/sh", "-c"]

          args = [local.updater_script]

          env {
            name  = "UPDATER_COMMAND"
            value = var.command
          }

          env {
            name  = "UPDATER_PERIOD"
            value = var.period
          }

          volume_mount {
            name       = "content"
            mount_path = "/usr/share/nginx/html"
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }

            requests = {
              cpu    = "0"
              memory = "0"
            }
          }
        }

        volume {
          name = "config"

          config_map {
            name = one(kubernetes_config_map_v1.config.metadata[*].name)
          }
        }

        volume {
          name = "content"

          empty_dir {
            medium     = "Memory"
            size_limit = "10Mi"
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [kubernetes_config_map_v1.config]
  }
}
