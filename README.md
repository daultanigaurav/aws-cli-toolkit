# AWS CLI Toolkit

A professional, interactive **shell scripting tool** for automating common AWS operations using the AWS CLI.

## 🚀 Features

### S3 Operations
- List all S3 buckets
- Upload files to S3
- Download files from S3

### EC2 Operations
- View EC2 instances
- Start, stop, or reboot EC2 instances

### Additional Features
- User-friendly interactive menu
- Error handling and logging
- Colorized output for readability
- AWS CLI prerequisites check

## 📁 Project Structure

```
aws-cli-toolkit/
├── aws-toolkit.sh          # Main script
├── install.sh              # Installation script
├── README.md               # Project documentation
├── logs/                   # Stores tool logs
├── config/                 # Stores configuration files
└── temp/                   # Stores temporary files
```

## 🛠 Installation

### Quick Start:

```bash
git clone <your-repo-url>
cd aws-cli-toolkit
chmod +x install.sh
./install.sh
```

### Manual Installation:

```bash
chmod +x aws-toolkit.sh install.sh
aws configure
```

## 🔹 Usage

```bash
./aws-toolkit.sh
```

Follow the on-screen menu to perform AWS operations.

## 🔹 AWS CLI Credentials

Make sure you have configured AWS CLI first:

```bash
aws configure
```

## 🔹 Security Best Practices

✅ Do not hardcode credentials in your script.  
✅ Use IAM roles or AWS CLI configured profiles.

## 📝 Logs

All operations are logged under:

```
logs/aws-toolkit.log
```

## ⚙ Permissions (IAM)

For **S3 operations**:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        { "Effect": "Allow", "Action": "s3:*", "Resource": "*" }
    ]
}
```

For **EC2 operations**:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        { "Effect": "Allow", "Action": "ec2:*", "Resource": "*" }
    ]
}
```

## 📝 Troubleshooting

✅ **AWS CLI not configured:**  
Run `aws configure`.

✅ **Permission denied:**  
Make sure IAM roles or credentials have proper permissions.

✅ **Command not found:**  
Make sure files have execute permission:
```bash
chmod +x aws-toolkit.sh
```

## 👨‍💻 Author

- GitHub: [daultanigaurav](https://github.com/daultanigaurav)

## 🙏 Acknowledgements

- AWS CLI for powerful scripting
- Shell scripting community for best practices

