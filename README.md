# 🚀 Two-Tier Web App — Flask + DynamoDB + Terraform
## Complete Step-by-Step Guide for VS Code on Windows

---

## 📁 Your Project Structure

```
project/
├── app.py                    ← Flask app (local testing only)
├── requirements.txt
├── templates/
│   └── index.html            ← Beautiful web page
└── terraform/
    ├── main.tf               ← ALL AWS infrastructure
    ├── user_data.sh          ← EC2 bootstrap (installs Flask)
    └── terraform.tfvars      ← Your config (edit this!)
```

---

## ✅ STEP 1 — One-Time AWS Pre-Setup (do this ONCE)

### 1A. Create an EC2 Key Pair
1. Open AWS Console → **EC2** → Left sidebar → **Key Pairs**
2. Click **Create key pair**
3. Name it: `my-keypair` (or anything you like)
4. Format: **PEM**
5. Click **Create** — the `.pem` file downloads automatically
6. Move the `.pem` file to your project's `terraform/` folder

### 1B. Make sure AWS CLI is configured in VS Code Terminal
Open VS Code Terminal (`Ctrl + ~`) and run:
```bash
aws sts get-caller-identity
```
You should see your Account ID. If not, run:
```bash
aws configure
```
Enter your AWS Access Key, Secret Key, region `us-east-1`, output `json`.

---

## ✅ STEP 2 — Edit terraform.tfvars

Open `terraform/terraform.tfvars` and change:
```hcl
key_pair_name = "my-keypair"   ← put the exact name you used in Step 1A
aws_region    = "us-east-1"
```

---

## ✅ STEP 3 — Deploy with Terraform

Open VS Code Terminal, navigate to the terraform folder:
```bash
cd terraform
```

**Initialize Terraform:**
```bash
terraform init
```

**Preview what will be created:**
```bash
terraform plan
```

**Deploy everything:**
```bash
terraform apply
```
Type `yes` when asked.

⏳ Wait about **2 minutes** for EC2 to finish installing Flask.

---

## ✅ STEP 4 — Open Your Website

After `terraform apply` finishes, you'll see:
```
Outputs:
  website_url = "http://3.89.xxx.xxx"
  ssh_command = "ssh -i my-keypair.pem ec2-user@3.89.xxx.xxx"
```

Open `http://3.89.xxx.xxx` in your browser — your beautiful app is live! 🎉

---

## ✅ STEP 5 — Test the App

1. Type your name in the input box
2. Click **Add Me ✨**
3. Your name appears in the **Visitors** list below
4. Data is saved to DynamoDB automatically

---

## 🔍 Troubleshooting

**Site not loading after 2 min?**
SSH in and check the service:
```bash
ssh -i my-keypair.pem ec2-user@<YOUR_IP>
sudo systemctl status flaskapp
sudo journalctl -u flaskapp -n 50
```

**Permission denied for .pem file?**
In VS Code Terminal (Git Bash or PowerShell):
```bash
icacls my-keypair.pem /inheritance:r /grant:r "%USERNAME%:R"
```

**Check DynamoDB has data:**
Go to AWS Console → DynamoDB → Tables → VisitorNames → Explore items

---

## 💰 AWS Free Tier Usage

| Resource       | What's Used          | Free Tier Limit         |
|----------------|----------------------|-------------------------|
| EC2            | t2.micro             | 750 hrs/month FREE      |
| DynamoDB       | PAY_PER_REQUEST      | 25 GB + 200M req FREE   |
| VPC/IGW/SG     | Networking           | Always FREE             |
| Data Transfer  | < 1 GB/month         | 1 GB/month FREE         |

✅ **This entire app runs within AWS Free Tier limits.**

---

## 🗑️ Destroy Everything (to avoid any charges)

When done, destroy all resources:
```bash
cd terraform
terraform destroy
```
Type `yes`. This deletes EC2, VPC, DynamoDB, IAM roles — everything.

---

## 🏗️ Architecture

```
Browser
   │  HTTP Port 80
   ▼
EC2 t2.micro (Amazon Linux 2023)
   ├── Nginx (reverse proxy on port 80)
   └── Gunicorn + Flask (port 5000)
          │  boto3 (AWS SDK)
          ▼
   DynamoDB Table: VisitorNames
   (Serverless, PAY_PER_REQUEST)
```

**IAM Role** on EC2 gives it permission to read/write DynamoDB — no hardcoded credentials!
