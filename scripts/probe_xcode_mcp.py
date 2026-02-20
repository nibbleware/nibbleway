import sys
import json
import subprocess
import time

def send_request(method, params=None, req_id=1):
    request = {
        "jsonrpc": "2.0",
        "id": req_id,
        "method": method,
        "params": params or {}
    }
    return json.dumps(request) + "\n"

def main():
    print("Connecting to Xcode MCP bridge via xcrun mcpbridge...")
    try:
        process = subprocess.Popen(
            ["xcrun", "mcpbridge"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1
        )
        
        # 1. Initialize
        print("Sending initialize request...")
        init_request = send_request("initialize", {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "probe", "version": "1.0.0"}
        }, req_id=1)
        process.stdin.write(init_request)
        process.stdin.flush()
        
        # Read responses until we get the init response or timeout
        while True:
            line = process.stdout.readline()
            if not line:
                break
            print(f"Received: {line.strip()}")
            resp = json.loads(line)
            if resp.get("id") == 1:
                break
        
        # 2. Initialized notification
        process.stdin.write(json.dumps({
            "jsonrpc": "2.0",
            "method": "notifications/initialized"
        }) + "\n")
        process.stdin.flush()
        
        # 3. List Tools
        print("\nSending tools/list request...")
        list_tools_request = send_request("tools/list", req_id=2)
        process.stdin.write(list_tools_request)
        process.stdin.flush()
        
        while True:
            line = process.stdout.readline()
            if not line:
                break
            print(f"Received: {line.strip()}")
            resp = json.loads(line)
            if resp.get("id") == 2:
                # Pretty print tools
                tools = resp.get("result", {}).get("tools", [])
                print(f"\nDiscovered {len(tools)} tools:")
                for tool in tools:
                    print(f"- {tool['name']}: {tool.get('description', 'No description')}")
                break
        
        process.terminate()
    except Exception as e:
        print(f"Error: {e}")
        if 'process' in locals():
            process.kill()

if __name__ == "__main__":
    main()
