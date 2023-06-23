# lambda-api-gateway-terraform

![Image](images/logo/i.png "Terraform")

## Getting started
Install Terraform
```
brew install terraform
```

Initialize the checkout to get the aws provider and initialize your local copy of the shared state
```
terraform init
```
After your state has been initialized it will generate a `.terraform.lock.hcl` file

Now compare your current state with your desired state:
```
terraform plan
```
Apply the changes:
```
terraform apply
```
