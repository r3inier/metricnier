terraform-init:
		cd terraform && terraform init

terraform-plan:
		cd terraform && terraform plan

terraform-apply:
		cd terraform && terraform apply -auto-approve

terraform-destroy:
		cd terraform && terraform destroy

# write makefile for destroying all Lambdas and re-uploading
terraform-update-lambdas:
	./src/scripts/terraform_update_lambdas.sh
