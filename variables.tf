variable "name" {
  type = string

  default = "dynamicfile"
}

variable "namespace" {
  type = string

  default = null
}

variable "nginx_image" {
  type = string

  default = "nginx:latest"

  description = "Nginx Docker image. Make sure to specify a docker image digest for production use"
}

variable "updater_image" {
  type = string

  default = null

  description = "Docker image to use for the updater. If not specified, the value of `nginx_image` will be used"
}

variable "command" {
  type = string

  description = "Command to be run periodically. Output of the command will be served by Nginx"
}

variable "period" {
  type = string

  default = "60"

  description = "Period in seconds"
}

variable "content_type" {
  type = string

  default = "text/html"
}
