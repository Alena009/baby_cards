import os
import urllib.request
import urllib.error

# Ensure directories exist
os.makedirs('assets/images/numbers', exist_ok=True)
os.makedirs('assets/images/cars', exist_ok=True)

def download_file(url, path):
    if os.path.exists(path):
        return
    
    try:
        req = urllib.request.Request(
            url, 
            data=None, 
            headers={'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.47 Safari/537.36'}
        )
        with urllib.request.urlopen(req, timeout=10) as response:
            with open(path, 'wb') as f:
                f.write(response.read())
            print(f"Downloaded {path}")
    except Exception as e:
        print(f"Error downloading {path}: {e}")

# Download Numbers 1-100
print("Downloading numbers...")
for i in range(1, 101):
    url = f'https://img.icons8.com/color/200/{i}.png'
    path = f'assets/images/numbers/{i}.png'
    download_file(url, path)

# Download Cars
print("\nDownloading cars...")
cars = {
    'bmw': 'https://img.icons8.com/color/200/bmw.png',
    'mercedes': 'https://img.icons8.com/color/200/mercedes-benz.png',
    'audi': 'https://img.icons8.com/color/200/audi.png',
    'tesla': 'https://img.icons8.com/color/200/tesla-logo.png',
    'ferrari': 'https://img.icons8.com/color/200/ferrari-badge.png',
    'vw': 'https://img.icons8.com/color/200/volkswagen.png',
    'toyota': 'https://img.icons8.com/color/200/toyota.png',
    'honda': 'https://img.icons8.com/color/200/honda.png',
    'ford': 'https://img.icons8.com/color/200/ford.png',
    'porsche': 'https://img.icons8.com/color/200/porsche.png',
    'lamborghini': 'https://img.icons8.com/color/200/lamborghini.png',
    'fiat': 'https://img.icons8.com/color/200/fiat-500.png',
    'mazda': 'https://img.icons8.com/color/200/mazda.png',
    'nissan': 'https://img.icons8.com/color/200/nissan.png',
    'hyundai': 'https://img.icons8.com/officel/200/hyundai.png',
    'kia': 'https://img.icons8.com/color/200/kia.png',
    'volvo': 'https://img.icons8.com/color/200/volvo.png',
    'jeep': 'https://img.icons8.com/color/200/jeep.png',
    'chevrolet': 'https://img.icons8.com/color/200/chevrolet.png',
    'lexus': 'https://img.icons8.com/color/200/lexus.png',
    'jaguar': 'https://upload.wikimedia.org/wikipedia/en/thumb/4/44/Jaguar_Cars_logo.svg/320px-Jaguar_Cars_logo.svg.png',
    'bentley': 'https://img.icons8.com/color/200/bentley.png',
    'minicooper': 'https://img.icons8.com/color/200/mini-cooper.png',
    'mitsubishi': 'https://img.icons8.com/color/200/mitsubishi.png',
    'subaru': 'https://img.icons8.com/color/200/subaru.png',
    'renault': 'https://img.icons8.com/color/200/renault.png',
    'peugeot': 'https://img.icons8.com/color/200/peugeot.png',
    'citroen': 'https://img.icons8.com/color/200/citroen.png',
    'skoda': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Skoda_logo2.svg/320px-Skoda_logo2.svg.png',
    'landrover': 'https://img.icons8.com/color/200/land-rover.png',
    'bugatti': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Bugatti_logo.svg/320px-Bugatti_logo.svg.png',
    'maserati': 'https://img.icons8.com/color/200/maserati.png',
    'alfa': 'https://img.icons8.com/color/200/alfa-romeo.png',
    'suzuki': 'https://img.icons8.com/color/200/suzuki.png',
    'opel': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Opel_logo_2023.svg/320px-Opel_logo_2023.svg.png',
    'dodge': 'https://img.icons8.com/color/200/dodge.png',
}

for name, url in cars.items():
    path = f'assets/images/cars/{name}.png'
    download_file(url, path)

print("Download complete.")
