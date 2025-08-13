# Firebase Remote Shell

A remote command execution system that uses Firebase Realtime Database as a communication bridge between client and target machines.

## ⚠️ Legal Disclaimer

**This tool is for educational and authorized testing purposes only.** 

- Only use this on systems you own or have explicit written permission to test
- Unauthorized access to computer systems is illegal in most jurisdictions
- The authors are not responsible for any misuse of this software
- Use responsibly and ethically

## 🔧 Components

### Client Side (`client.py`)
- Python script that sends commands to target machines
- Lists available connected devices
- Sends commands and retrieves output through Firebase
- Interactive shell interface

### Target Side (Batch Scripts)
- `firebase_cli_v2.bat` - Main agent that runs on target machines
- `automate.bat` / `automatev2.bat` - Installation scripts for persistence
- Monitors Firebase for incoming commands and executes them

## 📋 Prerequisites

### Client Requirements
- Python 3.x
- `requests` library (`pip install requests`)

### Target Requirements
- Windows operating system
- Internet connectivity
- `curl` command available (Windows 10+ has this built-in)

### Firebase Setup
1. Create a Firebase project at [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Enable Realtime Database
3. Set database rules to allow read/write (for testing only):
   ```json
   {
     "rules": {
       ".read": true,
       ".write": true
     }
   }
   ```
4. Copy your database URL

## 🚀 Setup

### 1. Configure Firebase URL
Create a `config.txt` file in the project directory:
```
https://your-project-id-default-rtdb.firebaseio.com
```

### 2. Client Setup
1. Install Python dependencies:
   ```bash
   pip install requests
   ```
2. Update the `FIREBASE_URL` in `client.py` with your Firebase database URL
3. Run the client: `python client.py`

### 3. Target Deployment
1. Copy the following files to the target machine:
   - `firebase_cli_v2.bat`
   - `config.txt`
   - `automate.bat` (optional, for persistence)

2. **Manual execution:**
   ```cmd
   firebase_cli_v2.bat
   ```

3. **Automated persistence (optional):**
   - Place files in the `extra/` directory
   - Run `automate.bat` - this will:
     - Move files to Windows startup folder
     - Start the agent
     - Delete the automation script

## 💻 Usage

### Client Interface
1. Run `python client.py`
2. Select a device from the list of connected machines
3. Enter commands to execute on the target
4. Type `back` to return to device selection
5. Type `exit` to quit

### Supported Commands
- Any Windows command line instruction
- `cd` commands are tracked and maintained across sessions
- `cls` command clears the client terminal locally

### Example Session
```
Firebase Remote Shell (type 'exit' to quit)

Available Devices:
1. DESKTOP-ABC123 (192.168.1.100)

Select device number (or 'exit'): 1

[DESKTOP-ABC123] $ dir
[Command output appears here]

[DESKTOP-ABC123] $ cd C:\Users
[DESKTOP-ABC123] $ dir
[Shows contents of C:\Users]

[DESKTOP-ABC123] $ back
```

## 🏗️ Architecture

```
Client (Python)  ←→  Firebase Database  ←→  Target (Batch)
```

1. **Client** sends commands to Firebase under `/commands/{device_id}`
2. **Target** polls Firebase every 5 seconds for new commands
3. **Target** executes commands and uploads results to Firebase
4. **Client** retrieves and displays the output

## 📁 File Structure

```
reverse_shell_cmd/
├── client.py              # Client-side command interface
├── firebase_cli_v2.bat    # Main agent for target machines
├── automate.bat           # Installation script (v1)
├── automatev2.bat         # Installation script (v2)
├── config.txt             # Firebase URL configuration
├── config.exampl.txt      # Configuration template
├── release/               # Deployment files
│   └── extra/            # Files for automated deployment
└── README.md             # This file
```

## 🔒 Security Considerations

- **Database Security**: Use proper Firebase security rules in production
- **Network Traffic**: All communication goes through Firebase (encrypted HTTPS)
- **Persistence**: Automation scripts achieve persistence via Windows startup folder
- **Detection**: Batch scripts may be detected by antivirus software
- **Logging**: Firebase retains command history and outputs

## 🐛 Troubleshooting

### Common Issues

1. **No devices appearing**
   - Check internet connectivity on target machine
   - Verify Firebase URL in config.txt
   - Ensure Firebase database rules allow read/write

2. **Commands not executing**
   - Check if target agent is running
   - Verify Firebase connectivity
   - Check Windows firewall settings

3. **Python client errors**
   - Install required dependencies: `pip install requests`
   - Check Firebase URL in client.py matches your project

### Debug Mode
Monitor Firebase database directly in the console to see real-time communication between client and target.

## 📝 Development Notes

- Commands are executed using `cmd /c` on the target
- Directory changes are tracked in `cd_command.txt` for session persistence
- Output is JSON-escaped before sending to Firebase
- Client polls for command completion with 10-second timeout
- Target agent runs in an infinite loop with 5-second intervals

## 🔄 Version History

- **v1.0**: Basic command execution
- **v2.0**: Added directory tracking and session persistence
- **v2.1**: Improved automation and stealth capabilities

---

**Remember**: This tool should only be used for legitimate security testing and educational purposes. Always obtain proper authorization before testing on any system you do not own.
