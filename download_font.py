import os
import urllib.request

os.makedirs('assets/fonts', exist_ok=True)

url = 'https://github.com/google/fonts/raw/main/ofl/greatvibes/GreatVibes-Regular.ttf'
path = 'assets/fonts/GreatVibes-Regular.ttf'

try:
    req = urllib.request.Request(
        url, 
        data=None, 
        headers={'User-Agent': 'Mozilla/5.0'}
    )
    with urllib.request.urlopen(req, timeout=10) as response:
        with open(path, 'wb') as f:
            f.write(response.read())
        print(f"Downloaded {path}")
except Exception as e:
    print(f"Error downloading font: {e}")
