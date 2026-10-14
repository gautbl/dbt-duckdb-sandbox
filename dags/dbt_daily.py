"""
### dbt_daily
Run dbt build every morning at 07:00 UTC.
"""

from __future__ import annotations
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator

with DAG(
    "dbt_daily",
    default_args={
        "owner": "analytics",
        "retries": 1,
        "retry_delay": timedelta(minutes=5),
    },
    description="Build dbt models daily",
    schedule="0 7 * * *",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=["dbt", "daily"],
) as dag:

    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command="cd /home/analytics/dbt_project && dbt build",
    )