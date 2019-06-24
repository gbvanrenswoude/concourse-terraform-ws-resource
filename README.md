# Concourse Terraform workspace resource

A Concourse Terraform resource that works with state.tf and workspaces. It tracks Terraform deployments using the serial across workspaces and roots.

## Installing

Bake the docker image with docker build and store it somewhere concourse can access it.  
Add the resource type to your pipeline:

```yaml
resource_types:
- name: terraform-ws
  type: docker-image
  source:
    repository: gbvanrenswoude/concourse-tf-ws-resource

resources:
{% for account in accountlist %}
- name: k8s-tf-deploy
  type: terraform-ws
  source:
    folder: git/terraform/main/products/eks  # input the hcl code to the job the using the git resource, input map it to the git folder
    workspace: "cluster_{{ account }}_{{ branch }}"
    assume_aws_role: arn:aws:iam::{{account}}:role/kube-admin
{% endfor %}

jobs:
- name: deploy-eks-cluster-in-{{ account }}
  plan:
  - get: cluster-code
    trigger: true
    passed: [staticanalysis-eks-cluster]
{% for account in accountlist %}
  - put: k8s-tf-deploy-in-{{account}}
    params:
      loglevel: DEBUG
      vars:
        env: "{{branch}}"
{% endfor %}
```

----
## Behavior

### `check`: Check for new versions of the Terraform state file.

Checks the serial of the Terraform state file. This allows the Terraform resource to only trigger if actual changes to infrastructure were made.

### `in`: Fetches the Terraform outputs from the statefile

Fetches the Terraform state file and returns the outputs in an `output` file.

### `out`: Runs a Terraform apply, taint or destroy.

Deploys, taints or destroys a Terraform configuration based on the provided parameters. Bumps and gives back the serial.


### Serial
This resource works with the Terraform state serial to track Terraform deployments across workspaces and Terraform roots.
Higher serial: Every state has a monotonically increasing "serial" number. If the destination state has a higher serial, Terraform will not allow you to write it since it means that changes have occurred since the state you're attempting to write.

Example of the serial in the tf-state file:
```json
{
    "version": 3,
    "terraform_version": "0.11.10",
    "serial": 12,
    "lineage": "7ce0ac04-83b0-c8f7-31a0-f2b377777603",
    "..more stuff.."
}
```


----
### Source Configuration
* `folder`: *Required.* Specify the Terraform root folder. (e.g. `input/terraform/main/products/someproduct`).
* `workspace`: *Optional.* Specify the workspace. Defaults to `default`.

Currently this resource supports the following backends: [`s3`](https://www.terraform.io/docs/backends/types/s3.html)
#### Source Configuration s3 backend part.
* `bucket`: *Required.* Specify the s3 bucket where Terraform stores it's state.
* `assume_aws_role`: *Optional.* When using AWS. If true, an AWS IAM role will be assumed before running the Terraform operation.
* `aws_region`: *Optional.* When using assume_aws_role in AWS, setting the aws_region is required for the API call. This defaults to eu-west-1 if you do not specify.
* `workspace_key_prefix`: *Optional.* Specify the workspace_key_prefix if you use this.
* `key`: *Optional.* Specify the Terraform state file name. Defaults to `terraform.tfstate`.
* `encrypt`: *Optional.* Specify if Terraform should encrypt it's state. Defaults to `false`. Other allowed values: `true`.
* `kms_key_id`: *Optional.* Specify the kms_key_id that Terraform should use for encryption.
* `dynamodb_table`: *Optional.* Specify the dynamodb_table that Terraform should use for state locking. By default, this is off. To use state locking, specify the tablename.

### Parameters

* `behavior`: *Optional.* Defaults to apply. Allowed values: `apply`, `taint` and `destroy`.
* `checkpoint_disable`: *Optional.* Check version information, broadcast security bulletins, etc. Is default off. Set to `false` to enable.
* `loglevel`: *Optional.* Set logging level for Terraform. TRACE, DEBUG, INFO, WARN, ERROR. Is default INFO.
* `print_outputs`: *Optional.* Set to `true` if you want to print the Terraform outputs in the log. Defaults to `false`.
* `vars`: *Optional.* Pass in variables to the Terraform deployment in a yml key value pair list. They will be prefixed with TF_VAR_* automatically.  

```yaml
vars:
  env: "dev"
  somekey: "somevalue"
```

* `targets`: *Optional.* Pass in a list of resource names known in your Terraform code if you want to apply just some specific resources.  

```yaml
targets:
- module.somemodule
- module.someothermodule
- aws_iam_role.eks-cluster-role
- aws_iam_role_policy_attachment.eks-cluster-AmazonEKSClusterPolicy
```

* `varfiles`: *Optional.* Pass in .tfvar files to the Terraform deployment in a yml list. Make sure the .tfvar files are available using an input.

```yaml
varfiles:
- vars/ami.tfvars
- vars/domain.tfvars
```

A valid .tfvar file would look like this:
```
echo "ami=\"$(cat resource-baseami-centos/id)\"" > vars/ami.tfvars
cat vars/ami.tfvars
ami=ami-123243565
```


----
### How to run locally
To run the check or in commands locally, use:
```
cd assets
cat ../test/sample_input_in.json | ./in './'
cat ../test/sample_input_in.json | ./in './' 2> /dev/null
```
and check
```
cat ../test/sample_input_check.json | ./check
cat ../test/sample_input_check.json | ./check 2> /dev/null
```
and out
```
cat ../test/sample_input_out.json | ./check
cat ../test/sample_input_out.json | ./check 2> /dev/null
```
Make sure you have python3 and your dependencies installed if you run the code directly and not via the Docker image.

If you run the Docker image, comment in the ENV vars in the Dockerfile bc corporate. Run the docker image and pass the sample input to stdin
```
docker build -t bob .
docker run --rm -it -v ~/.aws:/root/.aws bob
```
When in bob
```
cd /opt/resource
cat ../test/sample_input_in.json | ./in './'
```
----
☁ ☼  ☁

_̴ı̴̴̡̡̡ ̡͌l̡̡̡ ̡͌l̡*̡̡ ̴̡ı̴̴̡ ̡̡͡|̲̲̲͡͡͡ ̲▫̲͡ ̲̲̲͡͡π̲̲͡͡ ̲̲͡▫̲̲͡͡ ̲|̡̡̡ ̡ ̴̡ı̴̡̡ ̡͌l̡̡̡̡.__  
°º¤ø,¸¸,ø¤º°°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°°º¤ø,¸
