import requests

# Replace these with your own Strato login credentials
strato_username = "your_strato_username"
strato_password = "your_strato_password"

# Replace this with the hostname you want to update
hostname = "your_dns_hostname.example.com"

# Find the current IPv4 address using ifconfig.co
ip_address = requests.get("https://ifconfig.co/ip", headers={'Accept': 'application/json'}, proxies={'http': 'http://10.10.1.10:3128', 'https': 'http://10.10.1.10:1080'}).text.strip()

# Construct the URL to update the host
url = f"https://dyndns.strato.com/nic/update?hostname={hostname}&myip={ip_address}"

# Perform the request to update the host
response = requests.get(url, auth=(strato_username, strato_password), headers={'Accept': 'application/json'})

# Check the response and print a message
if response.text.strip() == f"good {ip_address}":
    print("DNS host successfully updated")
else:
    print(f"Error updating DNS host: {response.text.strip()}")
