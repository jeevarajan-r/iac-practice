variable "instance_name" {
    description = "Value of the EC2 instance's name tag"
    type = string
    default = "image-upload-app"
  
}
variable "instance_type" {
    description = "The EC2 instance's type"
    type = string
    default = "t2.micro"  

    validation {
        condition     = contains(["t2.micro", "t3.micro"], var.instance_type)
        error_message = "Only t2.micro and t3.micro are allowed for cost control."
  }
}

variable "github_url" {
    description = "Github URL to clone the repository"
    type = string
    default = "https://github.com/jeevarajan-r/iac-practice.git"
}

variable "app_port" {
    description = "Port number for the application"
    type = number
    default = 5000  
}

variable "ssh_key_name" {
    description = "Name of the SSH key pair"
    type = string
    default = "app-deploy-key"
}

variable "ssh_key_path" {
    description = "Path to the SSH private key"
    type = string
    default = "~/.ssh/id_rsa"  
}