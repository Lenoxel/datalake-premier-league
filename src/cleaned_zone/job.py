import sys
import re
import logging
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql import DataFrame
import boto3

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

args = getResolvedOptions(sys.argv, ["JOB_NAME", "raw_bucket", "cleaned_bucket"])

sc = SparkContext()
glueCtx = GlueContext(sc)
spark = glueCtx.spark_session
job = Job(glueCtx)
job.init(args["JOB_NAME"], args)

RAW_PATH = f"s3://{args['raw_bucket']}/matches/"
OUTPUT_PATH = f"s3://{args['cleaned_bucket']}/matches/"

logger.info("Reading CSV files from raw zone...")


def read_csv_safe(path: str) -> DataFrame:
    return spark.read.option("header", "true").option("inferSchema", "true").csv(path)


s3_client = boto3.client("s3")

bucket = args["raw_bucket"]
prefix = "matches/"

paginator = s3_client.get_paginator("list_objects_v2")
file_list = [
    f"s3://{bucket}/{obj['Key']}"
    for page in paginator.paginate(Bucket=bucket, Prefix=prefix)
    for obj in page.get("Contents", [])
    if obj["Key"].endswith(".csv")
]

logger.info(f"Found {len(file_list)} files in raw zone.")

dfs = [read_csv_safe(path) for path in file_list]

df_raw = dfs[0]

for df_next in dfs[1:]:
    df_raw = df_raw.unionByName(df_next, allowMissingColumns=True)

logger.info(f"Original columns: {df_raw.columns}")
logger.info(f"Total rows: {df_raw.count()}")


def to_snake(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", name.strip().lower()).strip("_")


df = df_raw

for col in df_raw.columns:
    clean = to_snake(col)
    if col != clean:
        df = df.withColumnRenamed(col, clean)

column_map = {
    "date": "match_date_raw",
    "hometeam": "home_team",
    "awayteam": "away_team",
    "fthg": "home_goals",  # Full Time Home Goals
    "ftag": "away_goals",  # Full Time Away Goals
    "ftr": "result",  # H / D / A
    "hthg": "ht_home_goals",  # Half Time Home Goals
    "htag": "ht_away_goals",  # Half Time Away Goals
    "htr": "ht_result",
    "hs": "home_shots",
    "as": "away_shots",
    "hst": "home_shots_target",
    "ast": "away_shots_target",
    "hy": "home_yellow",
    "ay": "away_yellow",
    "hr": "home_red",
    "ar": "away_red",
}

for old, new in column_map.items():
    if old in df.columns:
        df = df.withColumnRenamed(old, new)
    else:
        logger.warning(
            f"Column '{old}' not found in data. It will be created with null values."
        )

df = df.withColumn(
    "match_date",
    F.when(
        F.length(F.col("match_date_raw")) <= 8,
        F.to_date(F.col("match_date_raw"), "dd/MM/yy"),
    ).otherwise(F.to_date(F.col("match_date_raw"), "dd/MM/yyyy")),
)

df = df.withColumn(
    "season",
    F.when(
        F.month("match_date") >= 8,
        F.concat(
            F.year("match_date").cast("string"),
            F.lit("-"),
            (F.year("match_date") + 1).cast("string"),
        ),
    ).otherwise(
        F.concat(
            (F.year("match_date") - 1).cast("string"),
            F.lit("-"),
            F.year("match_date").cast("string"),
        )
    ),
)

int_columns = [
    "home_goals",
    "away_goals",
    "ht_home_goals",
    "ht_away_goals",
    "home_shots",
    "away_shots",
    "home_shots_target",
    "away_shots_target",
    "home_yellow",
    "away_yellow",
    "home_red",
    "away_red",
]

for column in int_columns:
    df = df.withColumn(
        column, F.col(column) if column in df.columns else F.lit(None).cast("integer")
    )

df_critical = df.select(
    "match_date", "home_team", "away_team", "home_goals", "away_goals"
).filter(
    F.col("match_date").isNull()
    | F.col("home_team").isNull()
    | F.col("away_team").isNull()
    | F.col("home_goals").isNull()
    | F.col("away_goals").isNull()
)

missing_count = df_critical.count()

if missing_count > 0:
    logger.warning(
        f"Found {missing_count} rows with critical missing values. These rows will be dropped."
    )

df = df.filter(F.col("away_team").rlike("^[A-Za-z]"))

df = df.dropna(
    subset=["match_date", "home_team", "away_team", "home_goals", "away_goals"]
)

df = df.select(
    "match_date",
    "season",
    "home_team",
    "away_team",
    "home_goals",
    "away_goals",
    "result",
    "ht_home_goals",
    "ht_away_goals",
    "ht_result",
    "home_shots",
    "away_shots",
    "home_shots_target",
    "away_shots_target",
    "home_yellow",
    "away_yellow",
    "home_red",
    "away_red",
)

seasons = [row[0] for row in df.select("season").distinct().orderBy("season").collect()]

logger.info(f"Seasons found: {seasons}")
logger.info(f"Total matches after cleaning: {df.count()}")

logger.info(f"Writing Parquet to {OUTPUT_PATH}...")

(df.write.mode("overwrite").partitionBy("away_team", "match_date").parquet(OUTPUT_PATH))

logger.info("Job cleaned_zone completed.")

job.commit()
