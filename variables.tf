#variables for the separate modules

variable "image_tag_mutability" {
  type        = string
  default     = "IMMUTABLE"
  description = "repository default is IMMUTABLE"
}

#region
variable "region" {
  default = "us-east-1"
}

#list of tags for the app and envs being deployed
variable "tags" {
  type = map 
  default = {
     application = "demowebapp" 
     environment = "production"
}
}
#variable "tags" {
#  type = list(object({
#    application = string
#    environment = string
#  })) 
#  default = [{
#     application = "demowebapp" 
#     environment = "production"
#}]
#}

variable "container_port" {
  default = "80"
}

variable "lb_protocol" {
  default = "HTTP"
}

#App name
variable "demowebapp" {
  default = "demowebapp"
}

#Env name
variable "environment" {
  default = "produnction"
}

variable "lb_port" {
  default = "80"
}
variable "vpc" {
  default = "vpc-0a98db3ed8f535c3d"
}

variable "private_subnets" {
    default = ["subnet-02c17f45e87af3500", "subnet-01d205641e92d71bd"]
}


#number of containers for fargate 
variable "replicas" {
  default = "1"
}

# The name of the container
variable "container_name" {
  default = "demowebapp"
}

#min number of instances for as
variable "ecs_autoscale_min_instances" {
  default = "1"
}

#max number of instances and we are setting it to 2 because I am poor. 
variable "ecs_autoscale_max_instances" {
  default = "2"
}

#container image
variable "demowebapp_image" {
#  default = "860758160586.dkr.ecr.us-east-1.amazonaws.com/demo-app:latest"
  default = "public.ecr.aws/s4y9e8v1/demo:latest"
#  default = "nginx:latest"
}

variable "logs_retention_in_days" {
  type        = number
  default     = 90
  description = "number of days the logs will be held for before deleting"
}

variable "internal" {
  default = false
}

variable "deregistration_delay" {
  default = "10"
}

variable "health_check" {
  default = "/."
}

variable "health_check_interval" {
  default = "10"
}

variable "health_check_timeout" {
  default = "5"
}

variable "health_check_code" {
  default = "200"
}

variable "lb_access_logs_expiration_days" {
  default = "5"
}

#cpu scale down thresh hold for as
variable "ecs_as_cpu_low_threshold_per" {
  default = "30"
}

#cpu high thresh hold for as
variable "ecs_as_cpu_high_threshold_per" {
  default = "75"
}