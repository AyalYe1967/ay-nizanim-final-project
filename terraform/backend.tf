terraform {
  backend "s3" {
    bucket       = "ay-l-final-project-tfstate"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}