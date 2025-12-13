variable "project" {
}
  default     = {}
  type        = map(string)
  description = "Common tags to apply to all resources"
variable "tags" {

}
  type        = string
  description = "Environment (dev, staging, prod)"
variable "environment" {

}
  type        = string
  description = "Project name"

