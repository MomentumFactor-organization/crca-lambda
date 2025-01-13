# Lambdas

The lambda functions are saved in the lambdas folder, inside of the folder there are a subfolders structure containing all the files needed, and ready to be deployed.

To create new lambda functions we need to create a subfolder inside of the lambdas folder.

As we are working with **Python** and versions **above 3.10**, it should include the **lambda_function.py** file, which is a **standard for AWS**.

It can also include files necessary for the execution of the function, such as _sql, json,_ etc. files.

If you need to use a specific **Python library** that has not been created, you can follow the documentation in the corresponding file.

Lambda functions are created from the Terraform script, so it will be necessary to update the file and update the plans for the creation of the resource in AWS, in addition to including the environment variables, layers, and triggers.

If the creation of any other resource that uses the function as a trigger is also required, such as an SQS resource, it would be included in the Terraform script.

## Working locally

If you want to create a new function or modify an existing one, you must follow these steps. These steps assume that you have already cloned this repository on your local machine.

##### Requirements
- [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html)

[AWS SAM CLI Installation guide](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html)

## Create a new function

When creating a new function, and as mentioned in previous paragraphs, we must create a directory within the lambdas folder, trying to be as detailed and specific as possible in the name so that the purpose and/or use of that function is known to everyone.

```bash
mkdir -p lambdas/<function-name>
```

>Note:
We use the function name using dashes for spaces.

Then we create the name of the file for the function as: `lambda_function.py`

```bash
touch lambdas/<function-name>/function_file.py
```

>Note:
We use the function name using underscores for spaces.

As a quick reminder the name of the function inside of the file should be named:

```python
def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "body": "Run Lambda from local!"
    }
```

### Test a Lambda function locally
For local testing its required to create a file `template.yaml` with the requirements for the lambda function.

This file shouldn't be add it to the repository and wont be needed for the deploy, as we are using Terraform script adding the same requirements.

So the next example will work locally and you can test it before the deploy. For the deployment process check the documentation regarding those steps.

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Resources:
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: app.lambda_handler
      Runtime: python3.11
      CodeUri: .
      Events:
        ApiEvent:
          Type: Api
          Properties:
            Path: /lambda
            Method: get
```

If we need to pass some parameters to our function we can also create our `event.json` file and run it as follows.

```bash
sam local invoke "function-name" -e event.json
```

Debug Locally
If you need to debug, you can use a debugger like pdb in Python. For example:

Add import pdb; pdb.set_trace() to your code where you want to debug.
Run the function with a debug port:

```bash
sam local invoke --debug-port 5890 "MyFunction"
```

### Test a deployed function Lambda function with parameters

```bash
aws lambda invoke \
    --function-name <function-name> \
    --payload '{"key1": "value1", "key2": "value2"}' \
    response.json
```

## Conclusion
Once we're done working with our function, and we've tested it locally we can update the terraform plan and deploy the resources in our plan to test it in our development environment.

You can check out the documentation to perform these steps.
