# Layers

A layer its a library to be use for a lambda function, and could be large as 50 Mb tops. It could be included in multiple functions once its created.

## Create a Layer

In order to create a layer we must create a subfolder inside the layer folder.

```bash
mkdir -p layers/<layer-name>
cd layers/<layer-name>
```

Once inside the folder, we need to create a virtual environment which will contain the library and activate the environment.

```bash
virtualenv venv
source venv/bin/activate
```

Now, we need to install the library that we will be using, that can be installed with pip.

```bash
pip install <library> -t layers/<layer-name>/python/
```

Before deactivate the resource we will need to create the requirements.txt file.

```bash
pip freeze > requirements.txt
```

Then we will compress the file of the contents of the python folder.

```bash
zip -r layer.zip python/
```

## Deploy a Layer

We can modify the Terraform script to deploy the layer and keep the plans updated for each environment. You can add it at the end of the layers section.

```hcl
resource "aws_lambda_layer_version" "<layer_name>" {
  filename            = "layers/compressed/name-layer.zip"
  layer_name          = "${var.environment}-name-layer"
  compatible_runtimes = ["python3.9", "python3.10"]
  source_code_hash    = filebase64sha256("layers/compressed/name-layer.zip")
  description         = "Layer for named library"
}
```