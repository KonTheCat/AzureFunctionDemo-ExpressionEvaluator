import logging
import os
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

def get_credential():
    default_credential = DefaultAzureCredential()
    return default_credential

def set_blob_data(data, storageAccountName, credential, containerName, blobName):
    blob_service_client = BlobServiceClient(account_url = f"https://{storageAccountName}.blob.core.windows.net", credential = credential)
    blob_client = blob_service_client.get_blob_client(container = containerName, blob = blobName)
    blob_client.upload_blob(data, blob_type = "BlockBlob", overwrite = True)

def get_blob_data(storageAccountName, credential, containerName, blobName):
    blob_service_client = BlobServiceClient(account_url = f"https://{storageAccountName}.blob.core.windows.net", credential = credential)
    try:
        blob_client = blob_service_client.get_blob_client(container = containerName, blob = blobName)
        downloader = blob_client.download_blob(max_concurrency=1, encoding='UTF-8')
    except:
        return None
    data = downloader.readall()
    return data

storageAccountName = os.environ.get("storageAccountName")
questionsContainerName = os.environ.get("questionsContainerName")
answersContainerName = os.environ.get("answersContainerName")

def main(myblob: func.InputStream):
    logging.info(f"Python blob trigger function processed blob \n"
                 f"Name: {myblob.name}\n"
                 f"Blob Size: {myblob.length} bytes")
    
    name = myblob.name.split('/')[1]
    credential = get_credential()
    expression = get_blob_data(storageAccountName, credential, questionsContainerName, name)
    result = eval(expression)
    data = f'{expression} = {result}'
    logging.info(data)
    set_blob_data(data, storageAccountName, credential, answersContainerName, name)
    

