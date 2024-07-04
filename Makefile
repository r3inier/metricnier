terraform-init:
		cd terraform && terraform init

terraform-plan:
		cd terraform && terraform plan

terraform-apply:
		cd terraform && terraform apply -auto-approve

terraform-destroy:
		cd terraform && terraform destroy