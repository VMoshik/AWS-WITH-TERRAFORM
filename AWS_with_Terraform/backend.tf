terraform {
  backend "s3" {
    bucket = "moshikv9"
    key    = "moshikv9/terraformstate.tf"
    region = "us-east-1"
  }
}
