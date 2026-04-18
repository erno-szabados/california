from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
import joblib
import os
import numpy as np

app = FastAPI(title="California Housing Predictor")

MODEL_PATH = os.path.join("models", "model.pkl")
SCALER_PATH = os.path.join("models", "scaler.pkl")

model = None
scaler = None
expected_features = None


class FeaturesIn(BaseModel):
    features: List[float]


@app.on_event("startup")
def load_artifacts():
    global model, scaler, expected_features
    try:
        if not os.path.exists(MODEL_PATH) or not os.path.exists(SCALER_PATH):
            raise FileNotFoundError("Model or scaler file not found; run training first.")

        model = joblib.load(MODEL_PATH)
        scaler = joblib.load(SCALER_PATH)

        # Try to infer expected feature dimension from scaler or model
        if hasattr(scaler, "n_features_in_"):
            expected_features = int(scaler.n_features_in_)
        elif hasattr(model, "n_features_in_"):
            expected_features = int(model.n_features_in_)
        else:
            expected_features = None

        app.logger = getattr(app, "logger", None)
    except Exception as e:
        # Keep startup from crashing hard; endpoints will return proper errors
        model = None
        scaler = None
        expected_features = None
        print("Warning loading artifacts:", str(e))


@app.get("/health")
def health():
    return {"model_loaded": model is not None, "scaler_loaded": scaler is not None}


@app.post("/predict")
def predict(payload: FeaturesIn):
    if model is None or scaler is None:
        raise HTTPException(status_code=503, detail="Model artifacts not loaded on server.")

    features = payload.features
    if expected_features is not None and len(features) != expected_features:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid feature vector length: expected {expected_features}, got {len(features)}",
        )

    try:
        arr = np.asarray(features, dtype=float).reshape(1, -1)
    except Exception:
        raise HTTPException(status_code=400, detail="Could not parse feature values as floats.")

    try:
        Xs = scaler.transform(arr)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Scaling error: {e}")

    try:
        pred = model.predict(Xs)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Model prediction error: {e}")

    try:
        value = float(pred[0])
    except Exception:
        raise HTTPException(status_code=500, detail="Unexpected prediction output format.")

    return {"prediction": value}
