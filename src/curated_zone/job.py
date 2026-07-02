import sys
import logging
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql import functions as F

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

args = getResolvedOptions(sys.argv, ["JOB_NAME", "cleaned_bucket", "curated_bucket"])

# optional: choose output format via job argument `--output_format iceberg|parquet`
output_format = "parquet"
try:
    extra = getResolvedOptions(sys.argv, ["output_format"])
    output_format = extra.get("output_format", "parquet")
except Exception:
    # if not provided, default to parquet
    pass

sc = SparkContext()
glueCtx = GlueContext(sc)
spark = glueCtx.spark_session
job = Job(glueCtx)
job.init(args["JOB_NAME"], args)

INPUT_PATH = f"s3://{args['cleaned_bucket']}/matches/"
OUTPUT_PATH = f"s3://{args['curated_bucket']}/reports/"

logger.info(f"Reading parquet from {INPUT_PATH}")

df = spark.read.parquet(INPUT_PATH)

home = df.select(
    F.col("home_team").alias("team"),
    F.col("season"),
    F.col("home_goals").cast("integer").alias("goals_scored"),
    F.col("away_goals").cast("integer").alias("goals_conceded"),
    F.lit(True).alias("is_home"),
)

away = df.select(
    F.col("away_team").alias("team"),
    F.col("season"),
    F.col("away_goals").cast("integer").alias("goals_scored"),
    F.col("home_goals").cast("integer").alias("goals_conceded"),
    F.lit(False).alias("is_home"),
)

matches = home.union(away)

reports = (
    matches.groupBy("team", "season")
    .agg(
        F.count("*").alias("total_matches"),
        F.sum("goals_scored").alias("total_goals_scored"),
        F.sum("goals_conceded").alias("total_goals_conceded"),
        F.round(F.sum("goals_scored") / F.count("*"), 2).alias("avg_goals"),
        F.round(
            F.sum(F.when(F.col("is_home"), F.col("goals_scored")))
            / F.sum(F.when(F.col("is_home"), F.lit(1))),
            2,
        ).alias("avg_goals_home"),
        F.round(
            F.sum(F.when(~F.col("is_home"), F.col("goals_scored")))
            / F.sum(F.when(~F.col("is_home"), F.lit(1))),
            2,
        ).alias("avg_goals_away"),
    )
    .orderBy("team", "season")
)

logger.info(f"Unique teams found: {reports.select('team').distinct().count()}")

logger.info(f"Unique seasons found: {reports.select('season').distinct().count()}")

logger.info(f"Total rows (team x season): {reports.count()}")

logger.info(f"Writing Parquet to {OUTPUT_PATH}")

(reports.write.mode("overwrite").partitionBy("team").parquet(OUTPUT_PATH))

logger.info("Job curated_zone completed.")

job.commit()
