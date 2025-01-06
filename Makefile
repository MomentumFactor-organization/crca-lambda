TERRAFORM = terraform
PLAN_DIR = plans
ENV ?= develop

fmt:
	@echo "Formatting Terraform files..."
	$(TERRAFORM) fmt -recursive

validate:
	@echo "Validating Terraform configuration..."
	$(TERRAFORM) validate

plan:
	@echo "Generating plan for environment: $(ENV)"
	@mkdir -p $(PLAN_DIR)/$(ENV)
	$(TERRAFORM) init
	$(TERRAFORM) plan -var="environment=$(ENV)" -out=$(PLAN_DIR)/$(ENV)/plan.tfplan

apply:
	@echo "Applying plan for environment: $(ENV)"
	$(TERRAFORM) apply $(PLAN_DIR)/$(ENV)/plan.tfplan

clean:
	@echo "Cleaning plans for environment: $(ENV)"
	@rm -rf $(PLAN_DIR)/$(ENV)

clean-all:
	@echo "Cleaning all plans"
	@rm -rf $(PLAN_DIR)
