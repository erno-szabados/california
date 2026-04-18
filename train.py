from sklearn.datasets import fetch_california_housing
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
import joblib
import os
import json
import sys
from datetime import datetime


def main():
    data = fetch_california_housing()
    X, y = data.data, data.target

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    model = LinearRegression()
    model.fit(X_train_scaled, y_train)

    y_pred = model.predict(X_test_scaled)

    mae = mean_absolute_error(y_test, y_pred)
    mse = mean_squared_error(y_test, y_pred)
    r2 = r2_score(y_test, y_pred)

    print(f"MAE: {mae:.4f}")
    print(f"MSE: {mse:.4f}")
    print(f"R2: {r2:.4f}")

    # Save artifacts
    os.makedirs("models", exist_ok=True)
    model_path = os.path.join("models", "model.pkl")
    scaler_path = os.path.join("models", "scaler.pkl")
    metadata_path = os.path.join("models", "metadata.json")

    # Use compression to reduce size
    joblib.dump(model, model_path, compress=3)
    joblib.dump(scaler, scaler_path, compress=3)

    # Write metadata for reproducibility and tracking
    try:
        import sklearn as _sk
        sklearn_version = _sk.__version__
    except Exception:
        sklearn_version = None

    try:
        import joblib as _jb
        joblib_version = _jb.__version__
    except Exception:
        joblib_version = None

    metadata = {
        "created_at": datetime.utcnow().isoformat() + "Z",
        "python_version": sys.version.split()[0],
        "sklearn_version": sklearn_version,
        "joblib_version": joblib_version,
        "model_path": model_path,
        "scaler_path": scaler_path,
        "n_features_in": getattr(model, "n_features_in_", None),
        "train_size": len(X_train),
        "test_size": len(X_test),
    }

    with open(metadata_path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)

    print(f"Saved model to: {model_path}")
    print(f"Saved scaler to: {scaler_path}")
    print(f"Saved metadata to: {metadata_path}")


if __name__ == "__main__":
    main()
