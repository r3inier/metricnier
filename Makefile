terraform-init:
		cd terraform && terraform init

terraform-plan:
		cd terraform && terraform plan

terraform-apply:
		cd src/functions/auth_spotify && pip install -r requirements.txt -t .
		cd terraform && terraform apply -auto-approve
		
terraform-destroy:
		cd terraform && terraform destroy

terraform-update-lambdas:
	./src/scripts/terraform_update_lambdas.sh

auth_and_store_spotify:
	python3 ./src/scripts/auth_and_store_spotify.py
