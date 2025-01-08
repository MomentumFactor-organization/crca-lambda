TERRAFORM = terraform
PLAN_DIR = plans
ENV ?= production

default: deploy

init:
	@echo "Initializing Terraform..."
	$(TERRAFORM) init

fmt:
	@echo "Formatting Terraform files..."
	$(TERRAFORM) fmt -recursive

validate: init
	@echo "Validating Terraform configuration..."
	$(TERRAFORM) validate

plan: validate
	@echo "Generating plan for environment: $(ENV)"
	@mkdir -p $(PLAN_DIR)/$(ENV)
	$(TERRAFORM) plan -var="environment=$(ENV)" -out=$(PLAN_DIR)/$(ENV)/plan.tfplan

apply: plan
	@echo "Applying plan for environment: $(ENV)"
	$(TERRAFORM) apply $(PLAN_DIR)/$(ENV)/plan.tfplan

destroy:
	@echo "Destroying infrastructure for environment: $(ENV)"
	$(TERRAFORM) destroy -var="environment=$(ENV)"

clean:
	@echo "Cleaning plans for environment: $(ENV)"
	@rm -rf $(PLAN_DIR)/$(ENV)

clean-all:
	@echo "Cleaning all plans"
	@rm -rf $(PLAN_DIR)

deploy: fmt validate plan apply
	@echo "Deployment completed for environment: $(ENV)"
