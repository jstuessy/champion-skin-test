resource "aws_s3_bucket" "b" {
  bucket = "jstuessy-test-bucket-b"
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}