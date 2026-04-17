from flask import Flask, render_template, request, redirect, session
import boto3
import os

app = Flask(__name__)
app.secret_key = "very-secret-key"

# Hardcoded credentials (INTENTIONAL for learning)
USERNAME = "admin"
PASSWORD = "password123"


S3_BUCKET = os.environ.get("S3_BUCKET","")
S3_REGION = os.environ.get("AWS_REGION","")

if not S3_BUCKET or not S3_REGION:
    raise Exception("S3_BUCKET or AWS_REGION not set")


s3 = boto3.client("s3", region_name=S3_REGION)

@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        if request.form["username"] == USERNAME and request.form["password"] == PASSWORD:
            session["logged_in"] = True
            return redirect("/upload")
        return "Invalid credentials", 401
    return render_template("login.html")

@app.route("/upload", methods=["GET", "POST"])
def upload():
    if not session.get("logged_in"):
        return redirect("/")

    if request.method == "POST":
        file = request.files["image"]
        if file:
            s3.upload_fileobj(
                file,
                S3_BUCKET,
                file.filename,
                ExtraArgs={"ContentType": file.content_type}
            )
            return "Upload successful"

    return render_template("upload.html")

@app.route("/logout")
def logout():
    session.clear()
    return redirect("/")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)