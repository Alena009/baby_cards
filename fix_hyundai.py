import os
import urllib.request

url = 'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized/hyundai.png'
path = 'assets/images/cars/hyundai.png'

try:
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=10) as response:
        with open(path, 'wb') as f:
            f.write(response.read())
        print(f"Downloaded {path}")
except Exception as e:
    print(f"Error downloading {path}: {e}")
