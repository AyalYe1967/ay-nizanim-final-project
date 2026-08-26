terraform {
  backend "s3" {
    bucket = "ay-l-final-project-tfstate"
    key    = "terraform.tfstate"
    region = "us-east-1"
    #    dynamodb_table = "ay-l-final-project-tf-locks"
    encrypt = true
  }
}