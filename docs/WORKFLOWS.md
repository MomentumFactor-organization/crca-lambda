# Workflows

The Github workflows are a set og Github actions to run on the Github repository. In this particular case, the document is to create a new workflow for a new lambda function.

The Github workflow will work in the environments and branches from the repository to update the changes if the code in the function its updated, that will update the code in the AWS Lambda function.

## Create a Github Workflow to Deploy

In the following steps its described how to create a github workflow. 

All the github workflows are stored in the path `.github/workflows` and the name of the workflow will be the function of the lambda name using dashes instead spaces. The workflow its saved into a yaml file.

The following code its an example with the parts to substitute the function name.

```yaml
name: Deploy metrics

on:
  push:
    branches:
      - develop
      - staging
      - production
    paths:
      - '../../lambdas/<function-name>/**'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: false
        default: ''
      aws_region:
        description: 'AWS Region for deployment'
        required: false
        default: 'us-west-1'

jobs:
  deploy:
    runs-on: ubuntu-latest

    env:
      AWS_REGION: ${{ github.event.inputs.aws_region || 'us-west-1' }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v2.5.0
  
      - name: Set up Python
        uses: actions/setup-python@v2.3.0
        with:
          python-version: '3.11'
  
      - name: Determine environment and region
        id: setup-env
        run: |
          # Determine the environment
          if [[ -n "${{ github.event.inputs.environment }}" ]]; then
            echo "ENVIRONMENT=${{ github.event.inputs.environment }}" >> $GITHUB_ENV
          elif [[ "${GITHUB_REF_NAME}" == "production" ]]; then
            echo "ENVIRONMENT=production" >> $GITHUB_ENV
          elif [[ "${GITHUB_REF_NAME}" == "staging" ]]; then
            echo "ENVIRONMENT=staging" >> $GITHUB_ENV
          else
            echo "ENVIRONMENT=develop" >> $GITHUB_ENV
          fi
  
          # Determine the AWS region
          if [[ -n "${{ github.event.inputs.aws_region }}" ]]; then
            echo "AWS_REGION=${{ github.event.inputs.aws_region }}" >> $GITHUB_ENV
          else
            echo "AWS_REGION=us-west-1" >> $GITHUB_ENV
          fi
    
      - name: Package and deploy
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          ENVIRONMENT: ${{ env.ENVIRONMENT }}
          AWS_REGION: ${{ env.AWS_REGION }}
        run: |
          echo "Deploying to environment: $ENVIRONMENT in region: $AWS_REGION"
          rm -f ../../compressed/${ENVIRONMENT}-<function-name>.zip
          zip -r9 ../../compressed/${ENVIRONMENT}-<function-name>.zip ../../lambdas/<function-name>
          aws lambda update-function-code --region ${AWS_REGION} --function-name ${ENVIRONMENT}-<function-name> --zip-file fileb://../../compressed/${ENVIRONMENT}-<function-name>.zip
```

As a final comment, the secrets are stored per environment in the Settings section of the repository.
