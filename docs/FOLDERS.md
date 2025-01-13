# Folders structure

The following documentation allows us to understand the purpose of each folder within the repository and will help us remember where to add functions or perform maintenance to this repository.

The structure of the folders in the repository is as follows:

```
|.github
|--workflows
|compressed
|docs
|envs
|lambdas
|layers
|--compressed
|plans
|--develop
|--staging
|--production
|scripts
```

## Github

This folder and its workflows subfolder are where the GitHub actions for updating each feature are stored.

The instructions for creating a workflow for a new feature are defined in a separate document.

## Compressed

This folder contains the compressed files of the lambda functions to be deployed to the AWS infrastructure.

## Docs

In this folder you will find the project documentation files, some files will be stored within the folders for the definition of specific functions.

## Envs

This folder contains the definition of the environments used in Terraform for creating and/or updating the infrastructure.

## Lambdas

The lambdas folder contains a structure of subfolders with the names of the functions, each of which contains the files needed to build the lambda function.

Note:
When naming the function, we try to be as descriptive as possible regarding the use of that function. We will not include references to the environment or the name of the product, and we will preferably use lowercase letters separated by hyphens.

## Layers

If libraries that are not included are required for the development of a lambda function, we will use the layers folder.

The layers folder contains the structure of previously created layers, as well as a folder with the compressed files.

Note: Documentation for creating and updating layers and lambda functions is located in a separate document.

## Plans

In this folder the plans of the terraform structures will be kept, each one will be stored in a subfolder with the name of its environment.

So that when they are updated, the environments are not overwritten or destroyed.

## Scripts

This folder contains the scripts needed to be deployed in the Terraform infrastructure.

