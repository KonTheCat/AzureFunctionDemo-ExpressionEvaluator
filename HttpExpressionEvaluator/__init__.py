import logging

import azure.functions as func


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    expression = req.params.get('expression')
    if not expression:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            expression = req_body.get('expression')

    if expression:
        result = eval(expression)
        logging.info(f'{expression} = {result}') 
        return func.HttpResponse(f'{result}')
    else:
        return func.HttpResponse(
             "This HTTP triggered function executed successfully. Pass an expression in the query string or in the request body for a personalized response.",
             status_code=200
        )
