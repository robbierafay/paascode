variable "minio_endpoint" {
  type        = string
  description = "The MinIO endpoint."
}

variable "minio_access_key" {
  type        = string
  description = "The MinIO access key."
}

variable "minio_secret_key" {
  type        = string
  description = "The MinIO secret key."
}

variable "bucket_name" {
  type        = string
  description = "The name of the MinIO bucket."
}

variable "served_model_name" {
  type        = string
  description = "The served model name for VLLM."
  default     = "tubitak-model"
}

variable "gpu_request" {
  type        = number
  description = "Number of GPUs to request."
  default     = 2
}

variable "extra_engine_args" {
  type        = string
  description = "Extra arguments to pass to the VLLM engine."
  default     = ""
}

variable "vllm_image" {
  type        = string
  description = "The VLLM image to use."
  default     = "vllm/vllm-openai:v0.7.3"
}

variable "model_data_path" {
  type        = string
  description = "The path to the model data inside the MinIO bucket and the mount point inside the container (relative to /models)."
  default     = "model_data"
}

variable "namespace" {
  type        = string
  description = "The Kubernetes namespace to deploy to."
  default     = "default"
}


variable "host_name" {
  type        = string
  description = "The hostname to use for the VLLM service (e.g., vllm.example.com)."
}

variable "ssl_certificate" {
  type        = string
  description = "The SSL certificate for the hostname."
}

variable "ssl_private_key" {
  type        = string
  description = "The SSL private key for the hostname."
}

variable "ingress_class_name" {
  type        = string
  description = "The name of the ingress class to use."
  default = "nginx"
}

variable "gpu_type" {
  type = string
  default = "nvidia"
}

variable "clientcertificatedata" {
  description = "Kubeconfig client-certificate-data"
  type        = string
}

variable "clientkeydata" {
  description = "Kubeconfig client-key-data"
  type        = string
}

variable "certificateauthoritydata" {
  description = "Kubeconfig certificate-authority-data"
  type        = string
}

variable "hserver" {
  description = "Kubeconfig server"
  type        = string
}

variable "kubeconfig" {
  description = "Kubeconfig"
  type        = string
}

variable "memory_limit" {
  type        = string
  description = "Memory limit for the VLLM container."
  default     = "48Gi" 
}
