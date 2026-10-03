from fastapi import FastAPI

app = FastAPI(title="Pathnex Python Application")


@app.get("/")
def home():
    return {"message": "Hello from Pathnex Python Application"}


@app.get("/health")
def health():
    return {"status": "healthy"}
