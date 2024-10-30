import os
import logging
import json
import numpy
import joblib
import pandas as pd

COLUMN_NAMES = ["sepal_length", "sepal_width", "petal_length", "petal_width"]

def init():
    """
    This function is called when the container is initialized/started, typically after create/update of the deployment.
    You can write the logic here to perform init operations like caching the model in memory
    """
    global model
    # AZUREML_MODEL_DIR is an environment variable created during deployment.
    # It is the path to the model folder (./azureml-models/$MODEL_NAME/$VERSION)
    # Please provide your model's folder name if there is one
    model_path = "./downloaded_artifacts/named-outputs/best_model/model.pkl"
    # deserialize the model file back into a sklearn model
    model = joblib.load(model_path)
    logging.info("Init complete")

def run(raw_data):
    """
    This function is called for every invocation of the endpoint to perform the actual scoring/prediction.
    In the example we extract the data from the json input and call the scikit-learn model's predict()
    method and return the result back
    """
    logging.info("model 1: request received")
    
    data = json.loads(raw_data)["data"]
    data_df = pd.DataFrame(data, columns=COLUMN_NAMES)  # Fix: "code": "UserError", "message": "Expected column(s) 0 not found in fitted data.",
    
    result = model.predict(data_df)
    
    logging.info("Request processed")
    return result.tolist()
