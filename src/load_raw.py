import sys
from pathlib import Path
import io
import psycopg2
import pandas as pd

DSN = "host=localhost port=5432 dbname=postgres user=postgres password=postgres"
DATA_DIR = Path("data") / "raw"

def load_trips(conn, month):
    path = DATA_DIR / f"yellow_tripdata_{month}.parquet"

    df = pd.read_parquet(path)
    df.columns = [c.lower() for c in df.columns]
    df["_src_file"] = path.name

    cur = conn.cursor()
    cur.execute("DELETE FROM raw.yellow_trips WHERE _src_file = %s", (path.name,))
    copy_df(cur, df, "raw.yellow_trips", list(df.columns))
    conn.commit()

    print(df.shape)

def load_zones(conn):
    path = DATA_DIR / "taxi_zone_lookup.csv"

    df = pd.read_csv(path)
    df.columns = [c.lower() for c in df.columns]
    df["_src_file"] = path.name

    cur = conn.cursor()
    cur.execute("TRUNCATE raw.taxi_zone_lookup")
    copy_df(cur, df, "raw.taxi_zone_lookup", list(df.columns))
    conn.commit()

    print(df.shape)

def copy_df(cur, df, table, columns):
    buf = io.StringIO()
    df.to_csv(buf, index=False, header=False)
    buf.seek(0)
    cur.copy_expert(
        f"COPY {table} ({', '.join(columns)}) FROM STDIN WITH (FORMAT csv, NULL '')",
        buf,
    )

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Использование: python src/load_raw.py YYYY-MM")
        sys.exit()

    month = sys.argv[1]
    conn = psycopg2.connect(DSN)
    load_zones(conn)
    load_trips(conn, month)
    conn.close()