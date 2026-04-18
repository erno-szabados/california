# california

Quick usage

- Train and produce artifacts (model, scaler, metadata):

```bash
uv run python train.py
```

- Start the prediction API:

```bash
uv run python -m uvicorn app:app --host 127.0.0.1 --port 8000
```

- Example request (curl):

```bash
curl -X POST http://127.0.0.1:8000/predict -H "Content-Type: application/json" \
	-d '{"features":[8.3252,41.0,6.984127,1.023809,322.0,2.555556,37.88,-122.23]}'
```

Notes

- Training produces `models/model.pkl`, `models/scaler.pkl`, and `models/metadata.json` (metadata includes Python and package versions and dataset split sizes). The `models/` directory is gitignored — store artifacts in an external registry for sharing.
