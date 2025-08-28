variable "table_name" {
  type = string
}
variable "hash_key" {
  type = string
  default = "email"
}
variable "read_capacity" {
  type = number
  default = 5
}
variable "write_capacity" {
  type = number
  default = 5
}
variable "tags" {
  type = map(string)
  default = {}
}
