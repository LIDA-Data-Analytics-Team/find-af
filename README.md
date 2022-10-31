# FIND-AF: Atrial fibrillation risk model API

Atrial fibrillation (AF) is a common irregular heart rhythm disorder that increases the risk of stroke by five times. Lives can be saved by detecting undiagnosed AF in the general population and treating these people.

FIND-AF wants to develop a tool to identify people at risk of AF. A model has been developed which predicts AF risk given a person’s risk factors. FIND-AF want to make the model a publicly available research output by building an API to allow other tools to integrate with the model, e.g. enabling people to discover their own risk.

## Changelog

- Set up demo API that runs in Azure, with an endpoint that takes dummy parameters and returns a dummy output value (endpoint /af).
- Added documentation to reproduce the API repo and Azure build, set up with continuous deployment

## Todo

- Edit the /af endpoint to include greater input validation and sanitation
- Edit the /af endpoint to take the model's explanatory variables as input parameters
- Edit the /af endpoint to use the FIND-AF model to predict an AF risk given the inputs, and return the prediction

## Design

The API for the atrial fibrillation risk model is built as a Python Flask web app and hosted in Microsoft Azure as an Azure Function.

## Try it out

A test version of the API is hosted at [https://find-af-api-test.azurewebsites.net](https://find-af-api-test.azurewebsites.net). The test version is a dummy API, which doesn't use the AF model at all. There are two endpoints: the index of the site and /af, which returns the (fake) model output given input parameters. Try these URLs as example requests to the API:<br>
[https://find-af-api-test.azurewebsites.net](https://find-af-api-test.azurewebsites.net)<br>
[https://find-af-api-test.azurewebsites.net/af?par0=2&par1=2&par2=2](https://find-af-api-test.azurewebsites.net/af?par0=2&par1=2&par2=2)

## Reproduce the build

Here are steps you can follow to reproduce the API build in Azure. The steps use VS Code as it has useful extensions for interacting with Azure, but you can manually perform the steps without VS Code if you prefer.

1. Create a resource group in Azure for the Azure Function app and associated resources to live
1. Create a Function App in your new resource group
    - Publish as Code, not Docker Container
    - Runtime stack is Python, choose a new version
    - Linux OS (not optional)
    - Plan type Consumption (Serverless)
    - Let Azure create a storage account
    - Enable Application Insights if you want some monitoring capability but this may be useful for the production API
    - You don't need to enable Continuous deployment via GitHub Actions, as we'll do this later in a more controlled way
    - Give it some useful tags
    - Review the spec then create
1. Create an Azure Function project using VS Code (skip this step if you cloned this repo instead)
    - Create a folder that your repository will live in and give it a name
    - Initialise your folder as a Git repo and commit changes throughout
    - Open VS Code and open your new folder
    - Install the Azure Functions extension
    - Open command palette (CTRL+SHIFT+P) and type "azure functions create" and select the "Create New Project..." command
    - Select the folder that will contain the project (your new repo)
    - Select the language (Python)
    - Select the version (the version you used to create the Function App in Azure)
    - Select the HTTP trigger function template
    - Name the function
    - Select the authorisation level (anonymous is fine because the API requires no authentication)
    - This completes the create project command, which will create a bunch of files in your repo including a subfolder for your function. The function subfolder will have a function.json file containing config and an \_\_init\_\_.py script containing the function.
1. Configure the new Azure Function project (skip this step if you cloned this repo instead)
    - In requirements.txt, add `flask`
    - In \_\_init\_\_.py, add `from flask import Flask, request`
    - Your function in \_\_init\_\_.py will contain code that defines the function's response to an HTTP trigger. Replace the code with
      ```
      return func.WsgiMiddleware(app.wsgi_app).handle(req, context)
      ```
      This redirects the function invocations to the Flask app that contains the API code.
    - In function.json, after the methods attribute, add `"route": "/{*route}"`
    - In host.json, add
      ```
        "extensions": {
          "http": {
            "routePrefix": ""
          }
        },
        ```
    - These steps are documented in more detail on Microsoft's code sample for [Using Flask Framework with Azure Functions](https://learn.microsoft.com/en-gb/samples/azure-samples/flask-app-on-azure-functions/azure-functions-python-create-flask-app/)
1. Deploy the code to your Function App
    - Open command palette (CTRL+SHIFT+P), type "azure functions deploy" and select the "Deploy to Function App..." command
    - Select the subscription you're deploying to
    - Select the Function App resource you're deploying to
    - VS Code will do the rest
1. If you didn't clone this repo, push your code to a remote repo on GitHub
1. Create the GitHub Action for continuous deployment of the API
    - Go to the Function App in Azure and click the "Get publish profile" button
    - Copy the contents of the downloaded profile to your clipboard
    - Now go to your repo in GitHub, then to Settings > Secrets > Actions secrets and click the New repository secret button
    - Paste the profile from Azure into the Secret box
    - Name the secret AZURE_FUNCTIONAPP_PUBLISH_PROFILE
    - Use this Microsoft [guide to set up the GitHub Action](https://learn.microsoft.com/en-us/azure/azure-functions/functions-how-to-github-actions?tabs=python) that will automate the API deployment. With the Python tab selected, copy to your clipboard the full YAML at the bottom of the guide. 
    - Now go to your repo's Actions tab, hit the New workflow button then click "set up a workflow yourself"
    - This will open an editor to create a new workflow YAML file for your function. Paste in the YAML that you copied from the guide.
    - Feel free to rename your workflow
    - AZURE_FUNCTIONAPP_NAME should be the name of your Function App in Azure
    - PYTHON_VERSION should be the version you've used
    - By default the deployment will be trigger with every commit pushed to the repo, but this can be changed to another trigger if you choose
    - Commit the YAML file
    - If you're deployed on every push, the commit should have triggered the workflow run. Check it has run properly on the Actions tab.
