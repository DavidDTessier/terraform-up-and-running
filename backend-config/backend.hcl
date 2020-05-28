# Bucket details for storing state
bucket = "ddt-terraform-state"
region = "ca-central-1"

# DynamoDb details for gaing Lock on state
dynamodb_table = "my-terraform-state-locks"
encrypt = true # ensures state will be encrypted
