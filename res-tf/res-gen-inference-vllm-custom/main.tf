data "external" "env" {
  program = ["${path.module}/scripts/env.sh"]
}

locals {
  rest_endpoint = data.external.env.result["RCTL_REST_ENDPOINT"]
  api_key       = data.external.env.result["RCTL_API_KEY"]
  insecure      = data.external.env.result["RCTL_SKIP_SERVER_CERT_VALIDATION"] != "" ? true : false
}



data "http" "get_org" {
  url      = "https://${local.rest_endpoint}/auth/v1/projects/?limit=48&offset=0&order=ASC&orderby=name&q=defaultproject"
  insecure = local.insecure
  request_headers = {
    "X-RAFAY-API-KEYID" = "${local.api_key}"
    Accept              = "application/json"
  }
}

locals {
  response_data             = jsondecode(data.http.get_org.response_body)
  org_hash                  = local.response_data.results[0].organization_id
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
  }
}
resource "random_uuid" "api_key" {
}

resource "kubernetes_deployment" "vllm_model_server" {
  metadata {
    name      = "${var.namespace}-llm-deployment"
    namespace = resource.kubernetes_namespace.namespace.metadata.0.name
    labels = {
      app = var.namespace
    }
  }
  depends_on = [kubernetes_namespace.namespace, random_uuid.api_key]
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = var.namespace
      }
    }
    template {
      metadata {
        labels = {
          app = var.namespace
        }
      }
      spec {
        # volume {
        #   name = "model-cache"
        #   empty_dir {}
        # }

        # volumes:
        # - name: model-cache
        #   hostPath:
        #     path: /nfstest2/models/
        #     type: Directory
        volume {
          name = "model-cache"
          host_path {
            path = "${var.model_data_path}"
            type = "Directory"
          }
        }
        
        volume {
          name = "dshm"
          empty_dir {
            medium     = "Memory" 
            size_limit = "30Gi"
          }
        }
        # init_container {
        #   name  = "minio-downloader-init"
        #   image = "minio/mc"
        #   image_pull_policy = "IfNotPresent"
        #   command = [
        #     "/bin/sh",
        #     "-c",
        #   ]
        #   args = [
        #     <<-EOT
        #       # echo "Attempting to set MinIO alias..."
        #       set -e # Exit immediately if a command exits with a non-zero status.

        #       echo "Attempting to set MinIO alias..."
        #       echo "ednpoint: ${var.minio_endpoint}"
        #       echo "access key: ${var.minio_access_key}"
        #       echo "secret key: ${var.minio_secret_key}"
        #       echo "Setting MinIO alias..."
        #       mc alias set myminio "${var.minio_endpoint}" "${var.minio_access_key}" "${var.minio_secret_key}"
        #       echo "Alias set successfully."

        #       echo "Attempting to download model from myminio/${var.bucket_name}/${var.model_data_path}/ to /models/${var.served_model_name}..."
        #       mc cp --recursive myminio/${var.bucket_name}/${var.model_data_path}/ /models/${var.served_model_name}
        #       echo "Model downloaded successfully from MinIO."

        #       echo "Checking if model config file exists..."
        #       ls /models/${var.served_model_name}/config.json || exit 1
        #       echo "Model verification successful."
        #     EOT
        #   ]
        #   env {
        #     name  = "MINIO_ENDPOINT"
        #     value = var.minio_endpoint
        #   }
        #   env {
        #     name  = "MINIO_ACCESS_KEY"
        #     value = var.minio_access_key
        #   }
        #   env {
        #     name  = "MINIO_SECRET_KEY"
        #     value = var.minio_secret_key
        #   }
        #   volume_mount {
        #     name       = "model-cache"
        #     mount_path = "/models"
        #   }
        # }
        container {
          name  = "vllm"
          image = var.vllm_image
          command = [
            "/bin/sh",
            "-c",
          ]
          args = [
            "vllm serve /models --trust-remote-code --distributed-executor-backend mp --tensor-parallel-size ${var.gpu_request} --gpu-memory-utilization 0.9 --served-model-name ${var.served_model_name} --api-key ${random_uuid.api_key.result} ${var.extra_engine_args}"
          ]
          port {
            container_port = 8000
          }
          env {
            name  = "VLLM_LOGGING_LEVEL"
            value = "INFO"
          }
          volume_mount {
            name       = "model-cache"
            mount_path = "/models"
          }
          volume_mount {
            name       = "dshm"       # Must match the volume name defined above
            mount_path = "/dev/shm" # Mount it over the default /dev/shm
          }
          resources {
            limits = {
              "${var.gpu_type}.com/gpu" = var.gpu_request
              "memory"             = var.memory_limit
            }
            requests = {
              "${var.gpu_type}.com/gpu" = var.gpu_request
            }
          }
        }
      }
    }
    # progress_deadline_seconds = var.deployment_wait_timeout 
  }
  # timeouts {
  #   create = var.dep_timeout
  #   update = var.dep_timeout
  #   delete = var.dep_timeout
  # }
}

resource "kubernetes_service" "service" {
  metadata {
    name      = "${var.namespace}-llm-service"
    namespace = resource.kubernetes_namespace.namespace.metadata.0.name
    labels = {
      app = var.namespace
    }
  }
  depends_on = [ kubernetes_deployment.vllm_model_server ]
  spec {
    selector = {
      app = var.namespace
    }
    port {
      name        = "${var.namespace}-http"
      port        = 8000
      protocol    = "TCP"
      target_port = 8000
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_secret" "tls_secret" {
  metadata {
    name      = "${var.namespace}-llm-tls"
    namespace = resource.kubernetes_namespace.namespace.metadata.0.name
  }
  type = "kubernetes.io/tls"
  data = {
    "tls.crt" = var.ssl_certificate
    "tls.key" = var.ssl_private_key
  }
}

resource "kubernetes_ingress_v1" "vllm_ingress" {
  metadata {
    name      = "${var.namespace}-llm-ingress"
    namespace = resource.kubernetes_namespace.namespace.metadata.0.name
    annotations = {
      "kubernetes.io/ingress.class" = var.ingress_class_name
    }
  }
  spec {
    ingress_class_name = var.ingress_class_name
    tls {
      hosts      = ["${var.host_name}"]
      secret_name = "${var.namespace}-llm-tls"
    }
    rule {
      host = "${var.host_name}"
      http {
        path {
          path = "/"
          backend {
            service {
              name = resource.kubernetes_service.service.metadata.0.name
              port {
                number = 8000
              }
            }
          }
        }
      }
    }
  }
}
