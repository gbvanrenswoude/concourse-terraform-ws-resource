generate_tf_statefile() {
  # Because TF works path relative, some trickery is necessary to select the workspace and query out the state files if no Terraform root folder is available (in case of check or in)
  aws_region=$(jq -r '.source.aws_region // "eu-west-1"' < $payload)
  bucket=$(jq -r '.source.bucket // ""' < $payload)
  workspace_key_prefix=$(jq -r '.source.workspace_key_prefix // ""' < $payload)
  encrypt=$(jq -r '.source.encrypt // "false"' < $payload)
  dynamodb_table=$(jq -r '.source.dynamodb_table // ""' < $payload)
  key=$(jq -r '.source.key // "terraform.tfstate"' < $payload)

  if [ -z "$aws_region" ]; then
    echo 'Using eu-west-1 as state configuration region...'
    region='    region       = "eu-west-1"'
  else
    eval "region='    region       = \"${aws_region}\"'"
  fi

  if [ -z "$bucket" ]; then
    echo 'No aws s3 bucket specified in the source configuration with parameter bucket. This Terraform resource needs a backend config to track deployments. Exiting..'
    exit 1
  else
    eval "bucket='    bucket       = \"${bucket}\"'"
  fi

  if [ -z "$key" ]; then
    echo 'Using default state file name terraform.tfstate..'
    key='    key       = "terraform.tfstate"'
  else
    eval "key='    key       = \"${key}\"'"
  fi

  if [ -z "$workspace_key_prefix" ]; then
    echo 'No workspace_key_prefix specified in the source configuration with parameter workspace_key_prefix. Using the default Terraform setup..'
  else
    eval "workspace_key_prefix='    workspace_key_prefix       = \"${workspace_key_prefix}\"'"
  fi

  if [ -z "$dynamodb_table" ]; then
    echo 'No state locking configured. Continuing....'
  else
    eval "dynamodb_table='    dynamodb_table       = \"${dynamodb_table}\"'"
  fi

  if [ "$encrypt" = "true" ]; then
    encrypt='    encrypt              = true'
    echo 'Configuring Terraform state encryption...'
    kms_key_id=$(jq -r '.source.kms_key_id // ""' < $payload)
    if [ -z "$kms_key_id" ]; then
      echo 'No KMS key is specified. Configure the additional encryption parameters if you want to use state encryption.'
      exit 1
    else
      eval "kms_key_id='    kms_key_id       = \"${kms_key_id}\"'"
    fi
  else
    encrypt=""
  fi

  echo "debug env"
  env
  echo "Generating state access.."

  cat << EOF > state.tf
  terraform {
    backend "s3" {
  ${bucket}
  ${key}
  ${region}
  ${workspace_key_prefix}
  ${encrypt}
  ${kms_key_id}
  ${dynamodb_table}
    }
  }
EOF
  terraform fmt
  echo "debug statefile.."
  cat state.tf
}
