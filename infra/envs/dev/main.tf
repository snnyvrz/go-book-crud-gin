provider "aws" {
  region                      = "eu-north-1"
  access_key                  = "test"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true

  endpoints {
    s3 = "http://localhost:4566"
  }
}
