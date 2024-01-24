import logging
import os
import azure.functions as func
from shared import get_credential, get_blob_data, set_blob_data

bp_blob_expression_evaluator = func.Blueprint()

bp_blob_expression_evaluator.route(route= "blob_expression_evaluator")
@bp_blob_expression_evaluator.blob_trigger(arg_name="myblob", path= "questions/{name}", connection="blobTrigger_STORAGE") 
def blob_expression_evaluator(myblob: func.InputStream):
    logging.info(f"Python blob trigger function processed blob \n"
                 f"Name: {myblob.name}\n"
                 f"Blob Size: {myblob.length} bytes")
    
    storageAccountName = os.environ.get("storageAccountName")
    questionsContainerName = os.environ.get("questionsContainerName")
    answersContainerName = os.environ.get("answersContainerName")
    
    name = myblob.name.split('/')[1]
    credential = get_credential()
    expression = get_blob_data(storageAccountName, credential, questionsContainerName, name)
    result = eval(expression)
    data = f'{expression} = {result}'
    logging.info(data)
    set_blob_data(data, storageAccountName, credential, answersContainerName, name)