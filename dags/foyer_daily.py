"""
### foyer_daily_pipeline
Complete daily pipeline: check sources, build dbt models, run quality tests,
compact Iceberg tables, expire old snapshots, refresh BI cache.
"""

from __future__ import annotations
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.models.baseoperator import chain

DBT_DIR = "/home/analytics/dbt_project"


def _check_sources():
    """Simulate a source freshness check.

    In production this would use the dbt Python API or
    run 'dbt source freshness' and parse the result.
    """
    print("All sources are fresh. Proceeding.")


with DAG(
    "foyer_daily_pipeline",
    default_args={
        "owner": "analytics",
        "retries": 2,
        "retry_delay": timedelta(minutes=5),
        "email": ["analytics@foyer.lu"],
        "email_on_failure": True,
    },
    description="Daily data pipeline: ingest → dbt → quality → maintain → BI",
    schedule="0 6 * * *",          # 06:00 UTC daily (cron: minute-hour-day-month-dow)
    start_date=datetime(2024, 6, 1),
    catchup=False,
    tags=["foyer", "daily"],
) as dag:

    check_sources = PythonOperator(
        task_id="check_sources",
        python_callable=_check_sources,
    )

    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command=f"cd {DBT_DIR} && dbt build",
    )

    dbt_test = BashOperator(
        task_id="dbt_tests",
        bash_command=f"cd {DBT_DIR} && dbt test --store-failures",
    )

    ice_optimize = BashOperator(
        task_id="iceberg_optimize",
        bash_command="dbt run-operation optimize_tables",  # custom macro
    )

    ice_vacuum = BashOperator(
        task_id="iceberg_vacuum",
        bash_command="dbt run-operation expire_snapshots --args '{"'"retention_days"'" : 7}'",
    )

    refresh_bi = BashOperator(
        task_id="refresh_bi_cache",
        bash_command="curl -X POST https://bi.foyer.lu/api/refresh",
    )

    # --- dependencies ---

    check_sources >> dbt_build >> dbt_test

    # Iceberg maintenance runs after the pipeline succeeds
    dbt_test >> [ice_optimize, ice_vacuum]

    # BI refresh is the last step
    [ice_optimize, ice_vacuum] >> refresh_bi