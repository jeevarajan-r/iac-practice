variable "instance_name" {
    description = "Value of the EC2 instance's name tag"
    type = string
    default = "image-upload-app"
  
}
variable "instance_type" {
    description = "The EC2 instance's type"
    type = string
    default = "t2.micro"  
}