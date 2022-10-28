# FIND-AF: Atrial fibrillation risk model API

Atrial fibrillation (AF) is a common irregular heart rhythm disorder that increases the risk of stroke by five times. Lives can be saved by detecting undiagnosed AF in the general population and treating these people.

FIND-AF wants to develop a tool to identify people at risk of AF. A model has been developed which predicts AF risk given a person’s risk factors. FIND-AF want to make the model a publicly available research output by building an API to allow other tools to integrate with the model, e.g. enabling people to discover their own risk.

## Design

The API for the atrial fibrillation risk model is built as a Python Flask web app and hosted in Microsoft Azure as an Azure Function.
