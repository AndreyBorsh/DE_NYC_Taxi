import sys
from pathlib import Path

import requests

BASE_URL = "https://d37ci6vzurychx.cloudfront.net"
DATA_DIR = Path("data") / "raw"

def download(url, dest):
    if dest.exists():
        print(f"skip {dest.name}")
        return

    print(f"скачиваю {url}")

    response = requests.get(url, stream=True, timeout=60)
    response.raise_for_status()

    # временный путь
    tmp = dest.with_suffix(dest.suffix + ".part")

    with open(tmp, "wb") as f:
        for chunk in response.iter_content(chunk_size=1024 * 1024):
            f.write(chunk)
    tmp.rename(dest)
    print(f"готово {dest}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Использование: python src/download.py YYYY-MM")
        sys.exit()

    month = sys.argv[1]

    # 1) создать папку, если её нет
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    # 2) откуда качаем (URL)
    trips_url = f"{BASE_URL}/trip-data/yellow_tripdata_{month}.parquet"
    zones_url = f"{BASE_URL}/misc/taxi_zone_lookup.csv"

    # 3) куда сохраняем (пути)
    trips_dest = DATA_DIR / f"yellow_tripdata_{month}.parquet"
    zones_dest = DATA_DIR / "taxi_zone_lookup.csv"

    download(trips_url, trips_dest)
    download(zones_url, zones_dest)