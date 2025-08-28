# Create an SES email identity for sender. For domains, consider aws_ses_domain_identity instead.
resource "aws_ses_email_identity" "sender" {
  email = var.email_identity
  tags = var.tags
}
