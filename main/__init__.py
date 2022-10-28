import logging
from flask import Flask, request
import azure.functions as func

app = Flask(__name__)

# Code from Azure Functions
def main(req: func.HttpRequest, context: func.Context) -> func.HttpResponse:
    """Each request is redirected to the WSGI handler, 
    which passes requests to the Flask app.
    """
    logging.info('Python HTTP trigger function processed a request.')

    # name = req.params.get('name')
    # if not name:
    #     try:
    #         req_body = req.get_json()
    #     except ValueError:
    #         pass
    #     else:
    #         name = req_body.get('name')
    # if name:
    #     return func.HttpResponse(f"Hello, {name}. This HTTP triggered function executed successfully.")
    # else:
    #     return func.HttpResponse(
    #          "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response.",
    #          status_code=200
    #     )

    # The Azure Function invocation passes requests to "app", the Flask app
    return func.WsgiMiddleware(app.wsgi_app).handle(req, context)


# Code for Flask app
@app.route('/')
def index():
    """API homepage, simply prints hello to let you know it's running and ready to accept an AF query."""
    return 'Hello!'


@app.route('/af')
def get_af_risk():
    """Return AF risk score given user's input."""
    model_par0 = request.args.get('par0', None, int)
    model_par1 = request.args.get('par1', None, int)
    model_par2 = request.args.get('par2', None, int)

    output = model_par0 * model_par1 * model_par2
    return {'AF risk' : output}

