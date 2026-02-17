from PIL import Image

# Load the icon
icon = Image.open('assets/icon/icon.png').convert('RGBA')
width, height = icon.size

# Get pixel data
pixels = icon.load()

# Sample the blue color from the top-left area where background should be
# Try multiple positions to find a good blue sample
sample_x, sample_y = int(width * 0.3), int(height * 0.1)  # Top area, offset from corner
blue_color = pixels[sample_x, sample_y]

# If that's not blue enough, use a known blue value
if blue_color[2] < 200:  # Blue channel should be high
    # Use a nice blue gradient color similar to the background
    blue_color = (100, 180, 255, 255)  # Light blue

print(f"Image size: {width}x{height}")
print(f"Blue reference color: {blue_color}")

# Define corner regions - be more aggressive
corner_size = int(min(width, height) * 0.20)  # 20% of image size for corners

# Function to check if a pixel should be replaced
def should_replace(pixel, blue_ref):
    # If pixel is very close to blue, keep it
    r_diff = abs(pixel[0] - blue_ref[0])
    g_diff = abs(pixel[1] - blue_ref[1])
    b_diff = abs(pixel[2] - blue_ref[2])
    
    # If it's already blue-ish, keep it
    if r_diff < 30 and g_diff < 30 and b_diff < 30:
        return False
    
    # Replace if it's light colored (white, pink, beige, etc.)
    # or if it's not part of the main subject
    avg_color = (pixel[0] + pixel[1] + pixel[2]) / 3
    return avg_color > 180  # Light colors

# Replace corner pixels
replaced_count = 0
for y in range(height):
    for x in range(width):
        # Check if we're in a corner region
        in_top_left = x < corner_size and y < corner_size
        in_top_right = x > width - corner_size and y < corner_size
        in_bottom_left = x < corner_size and y > height - corner_size
        in_bottom_right = x > width - corner_size and y > height - corner_size
        
        if in_top_left or in_top_right or in_bottom_left or in_bottom_right:
            if should_replace(pixels[x, y], blue_color):
                pixels[x, y] = blue_color
                replaced_count += 1

# Save the result
icon.save('assets/icon/icon.png')
print(f"Icon corners fixed! Replaced {replaced_count} pixels with blue background.")
