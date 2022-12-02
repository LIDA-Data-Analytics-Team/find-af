import logging
from flask import Flask, request
import azure.functions as func

# Import sklearn random forest model that'll be used with loaded
# model joblib object to predict AF.
from sklearn.ensemble import RandomForestRegressor
from joblib import load

app = Flask(__name__)

# Code from Azure Functions
def main(req: func.HttpRequest, context: func.Context) -> func.HttpResponse:
    """Each request is redirected to the WSGI handler, 
    which passes requests from the Function to the Flask app
    so we can handle requests using Flask code.
    """
    logging.info('Python HTTP trigger function processed a request.')

    # The Azure Function invocation passes requests to "app", the Flask app
    return func.WsgiMiddleware(app.wsgi_app).handle(req, context)


# Code for Flask app
@app.route('/')
def index():
    """API homepage, prints basic message to show it's running and ready to accept an AF query."""
    return """Welcome to the FIND-AF API!
    """


@app.route('/af')
def get_af_risk():
    """Return AF risk score given user's input.

    /af endpoint takes the input parameters par0, par1 and par2, which are dummy variables
    that represent explanatory variables for a model that predicts AF risk. It then returns
    an AF risk, given the input parameter values. The dummy model output multiples all
    input parameters together. E.g., try (result should be 8):
    https://find-af-api-test.azurewebsites.net/af?par0=2&par1=2&par2=2

    Parameters
    ----------
    par0 : int
        Dummy var that acts as a fake model explanatory variable, to be used to predict AF risk. 
    par1 : int
        Dummy var that acts as a fake model explanatory variable, to be used to predict AF risk.
    par2 : int
        Dummy var that acts as a fake model explanatory variable, to be used to predict AF risk.

    Returns
    -------
    dict
        Model prediction of AF risk, given input pars, as JSON HTTP response.
        The dummy model output multiplies all input pars.
    """
    #model_par0 = request.args.get('par0', None, int)
    #model_par1 = request.args.get('par1', None, int)
    #model_par2 = request.args.get('par2', None, int)

    # The inputs are sanitised to data type as they're parsed,
    # but include more validation and sanitation here. Mostly
    # can't be done until we know what the real input pars will be.
    
    # This is where we'll send the real input vars to a proper AF model
    # The model will be written in Python scikit-learn, saved as a
    # pickle/joblib file. Load the model then make a prediction given
    # the input pars.

    # Shape input pars into np array of len 1. The element is itself an array
    # of len = number of pars:
    # X = [[input_pars]]
    X = [[0, 0, 0, 0]]

    # Load model. Currently dummy model, swap out for real model in prod.
    af_model = load('./data/demo_model.joblib')
    af_pred = af_model.predict(X)

    return {'AF risk' : af_pred[0]}