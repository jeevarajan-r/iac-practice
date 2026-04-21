import boto3
import os
import time
from botocore.exceptions import EndpointConnectionError


TERMINAL_STATUSES = {
    "LOAD_COMPLETED",
    "LOAD_COMPLETED_WITH_ERRORS",
    "LOAD_FAILED",
    "LOAD_CANCELLED",
}

SUCCESS_STATUSES = {
    "LOAD_COMPLETED",
    "LOAD_COMPLETED_WITH_ERRORS",
}


def _env_bool(name: str, default: bool = False) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default

    return raw.strip().lower() in {"1", "true", "yes", "y", "on"}


def _build_client():
    return boto3.client(
        "neptunedata",
        region_name=os.environ["AWS_REGION"],
        endpoint_url=os.environ["NEPTUNE_LOADER_ENDPOINT_URL"],
    )

def _start_loader_with_retry(client, **kwargs):
    attempts = int(os.getenv("NEPTUNE_LOADER_START_RETRIES", "10"))
    delay = int(os.getenv("NEPTUNE_LOADER_RETRY_DELAY_SECONDS", "10"))

    for i in range(attempts):
        try:
            return client.start_loader_job(**kwargs)
        except EndpointConnectionError:
            if i == attempts - 1:
                raise
            time.sleep(delay)

def lambda_handler(event, context):
    action = event.get("action", "start").lower()
    client = _build_client()

    if action == "status":
        load_id = event.get("load_id") or event.get("loadId")
        if not load_id:
            raise ValueError("Missing required field: load_id")

        # Prefer the specific status API; if unavailable in runtime SDK, fall back to list API.
        try:
            response = client.get_loader_job_status(loadId=load_id)
            payload = response.get("payload", {})
            overall_status = payload.get("overallStatus", {})
            status = overall_status.get("status", "UNKNOWN")
        except AttributeError:
            response = client.list_loader_jobs()
            payload = response.get("payload", {})
            load_statuses = payload.get("loadStatuses", [])
            matched = next((item for item in load_statuses if item.get("loadId") == load_id), None)
            if matched is None:
                status = "UNKNOWN"
                overall_status = {"status": status, "message": "loadId not found in list_loader_jobs response"}
            else:
                overall_status = matched
                status = matched.get("status", "UNKNOWN")

        return {
            "action": "status",
            "loadId": load_id,
            "status": status,
            "isTerminal": status in TERMINAL_STATUSES,
            "succeeded": status in SUCCESS_STATUSES,
            "overallStatus": overall_status,
        }

    if action != "start":
        raise ValueError(f"Unsupported action: {action}")

    # S3 prefix passed from GitHub Actions
    s3_source = event["s3_source"]

    
    response = _start_loader_with_retry(
        client,
        source=s3_source,
        format="csv",
        s3BucketRegion=os.environ["AWS_REGION"],
        iamRoleArn=os.environ["NEPTUNE_IAM_ROLE_ARN"],
        failOnError=_env_bool("NEPTUNE_FAIL_ON_ERROR", default=False),
        parallelism="HIGH",
    )


    return {
        "action": "start",
        "status": "STARTED",
        "loadId": response["payload"]["loadId"]
    }