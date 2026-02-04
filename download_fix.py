import os
import urllib.request

cars = {
    'skoda': 'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized/skoda.png',
    'bugatti': 'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized/bugatti.png',
    'opel': 'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized/opel.png',
}

for name, url in cars.items():
    path = f'assets/images/cars/{name}.png'
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=10) as response:
            with open(path, 'wb') as f:
                f.write(response.read())
            print(f"Downloaded {name}.png")
    except Exception as e:
        print(f"Error downloading {name}: {e}")
