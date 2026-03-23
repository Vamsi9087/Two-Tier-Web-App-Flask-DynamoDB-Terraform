#!/bin/bash
set -e

yum update -y
yum install -y python3 python3-pip nginx

mkdir -p /home/ec2-user/app/templates

cat > /home/ec2-user/app/app.py << 'EOF'
from flask import Flask, request, jsonify, render_template
import boto3, uuid
from datetime import datetime

app = Flask(__name__)
dynamodb = boto3.resource('dynamodb', region_name='ap-south-2')
table = dynamodb.Table('VisitorNames')

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/submit', methods=['POST'])
def submit():
    data = request.get_json()
    name = data.get('name', '').strip()
    if not name:
        return jsonify({'error': 'Name is required'}), 400
    table.put_item(Item={'id': str(uuid.uuid4()), 'name': name, 'timestamp': datetime.utcnow().isoformat()})
    return jsonify({'message': f'Welcome, {name}! You have been registered.'}), 200

@app.route('/visitors', methods=['GET'])
def get_visitors():
    items = table.scan().get('Items', [])
    items.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
    return jsonify(items), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

cat > /home/ec2-user/app/templates/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>Visitor Register</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet"/>
<style>
:root{--bg:#0a0a1a;--accent4:#a29bfe;--accent3:#6bcbff;--accent1:#ff6b6b;--text:#f0f0ff;--subtext:rgba(240,240,255,0.55);--border:rgba(255,255,255,0.1);--card:rgba(255,255,255,0.05)}
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'DM Sans',sans-serif;background:var(--bg);color:var(--text);min-height:100vh;overflow-x:hidden}
.bg{position:fixed;inset:0;z-index:0;background:radial-gradient(ellipse 80% 60% at 20% 30%,rgba(162,155,254,.18),transparent 60%),radial-gradient(ellipse 70% 50% at 80% 70%,rgba(107,203,255,.15),transparent 60%),#0a0a1a;animation:hue 12s ease-in-out infinite alternate}
@keyframes hue{to{filter:hue-rotate(30deg)}}
.orb{position:fixed;border-radius:50%;filter:blur(60px);opacity:.22;animation:float linear infinite;pointer-events:none}
.o1{width:320px;height:320px;background:var(--accent4);top:-80px;left:-80px;animation-duration:18s}
.o2{width:260px;height:260px;background:var(--accent3);bottom:-60px;right:-60px;animation-duration:22s;animation-delay:-8s}
.o3{width:180px;height:180px;background:var(--accent1);top:45%;left:62%;animation-duration:15s;animation-delay:-4s}
@keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-35px)}}
.wrap{position:relative;z-index:1;max-width:820px;margin:0 auto;padding:60px 20px 80px}
header{text-align:center;margin-bottom:52px;animation:fadeD .8s both}
@keyframes fadeD{from{opacity:0;transform:translateY(-24px)}to{opacity:1;transform:translateY(0)}}
.badge{display:inline-block;background:linear-gradient(135deg,var(--accent4),var(--accent3));color:#fff;font-size:11px;letter-spacing:3px;text-transform:uppercase;padding:6px 18px;border-radius:100px;margin-bottom:20px}
h1{font-family:'Playfair Display',serif;font-size:clamp(2.2rem,6vw,3.8rem);font-weight:900;background:linear-gradient(135deg,#fff,var(--accent4) 50%,var(--accent3));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;margin-bottom:12px}
.sub{color:var(--subtext);font-size:1rem;font-weight:300;max-width:440px;margin:0 auto}
.card{background:var(--card);border:1px solid var(--border);border-radius:22px;backdrop-filter:blur(20px);padding:36px;margin-bottom:28px;animation:fadeU .8s .15s both;transition:box-shadow .4s}
.card:hover{box-shadow:0 0 36px rgba(162,155,254,.14)}
@keyframes fadeU{from{opacity:0;transform:translateY(24px)}to{opacity:1;transform:translateY(0)}}
.ct{font-family:'Playfair Display',serif;font-size:1.3rem;font-weight:700;margin-bottom:22px}
.ct span{color:var(--accent4)}
.row{display:flex;gap:12px;flex-wrap:wrap}
input{flex:1;min-width:180px;background:rgba(255,255,255,.06);border:1.5px solid rgba(255,255,255,.12);border-radius:12px;color:#fff;font-family:'DM Sans',sans-serif;font-size:1rem;padding:14px 18px;outline:none;transition:border-color .3s,box-shadow .3s}
input::placeholder{color:var(--subtext)}
input:focus{border-color:var(--accent4);box-shadow:0 0 0 4px rgba(162,155,254,.12)}
button{background:linear-gradient(135deg,var(--accent4),var(--accent3));color:#fff;border:none;border-radius:12px;font-family:'DM Sans',sans-serif;font-size:1rem;font-weight:500;padding:14px 28px;cursor:pointer;transition:transform .2s,box-shadow .3s;position:relative;overflow:hidden}
button:hover{transform:translateY(-2px);box-shadow:0 8px 24px rgba(162,155,254,.35)}
.shine{position:absolute;inset:0;background:linear-gradient(105deg,transparent 40%,rgba(255,255,255,.22) 50%,transparent 60%);transform:translateX(-100%);transition:transform .5s}
button:hover .shine{transform:translateX(100%)}
.vh{display:flex;justify-content:space-between;align-items:center;margin-bottom:20px;flex-wrap:wrap;gap:10px}
.cb{background:rgba(162,155,254,.14);border:1px solid rgba(162,155,254,.28);border-radius:100px;font-size:.78rem;color:var(--accent4);padding:4px 12px}
.rb{background:transparent;border:1.5px solid var(--border);color:var(--subtext);font-size:.82rem;padding:7px 16px;border-radius:100px;box-shadow:none}
.rb:hover{border-color:var(--accent4);color:var(--accent4);transform:none;box-shadow:none}
.vl{display:flex;flex-direction:column;gap:9px}
.vi{display:flex;align-items:center;gap:14px;background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.07);border-radius:12px;padding:12px 16px;animation:sli .35s both;transition:background .3s}
.vi:hover{background:rgba(162,155,254,.07)}
@keyframes sli{from{opacity:0;transform:translateX(-14px)}to{opacity:1;transform:translateX(0)}}
.av{width:40px;height:40px;border-radius:50%;flex-shrink:0;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:.95rem;color:#fff}
.vn{font-weight:500}
.vt{font-size:.75rem;color:var(--subtext);margin-top:2px}
.vnum{margin-left:auto;font-size:.72rem;color:var(--subtext)}
.empty{text-align:center;padding:36px;color:var(--subtext)}
.sp{width:26px;height:26px;border:3px solid rgba(255,255,255,.1);border-top-color:var(--accent4);border-radius:50%;animation:spin .8s linear infinite;margin:20px auto}
@keyframes spin{to{transform:rotate(360deg)}}
#toast{position:fixed;bottom:28px;left:50%;transform:translateX(-50%) translateY(70px);background:linear-gradient(135deg,var(--accent4),var(--accent3));color:#fff;font-size:.9rem;padding:12px 26px;border-radius:100px;z-index:100;transition:transform .45s cubic-bezier(.22,1,.36,1),opacity .45s;opacity:0;pointer-events:none}
#toast.show{transform:translateX(-50%) translateY(0);opacity:1}
#toast.err{background:linear-gradient(135deg,var(--accent1),#ff9f43)}
footer{text-align:center;color:var(--subtext);font-size:.78rem;margin-top:48px}
footer span{color:var(--accent4)}
</style>
</head>
<body>
<div class="bg"></div>
<div class="orb o1"></div><div class="orb o2"></div><div class="orb o3"></div>
<div class="wrap">
  <header>
    <div class="badge">Welcome Register</div>
    <h1>Sign Your Name<br>to the Universe</h1>
    <p class="sub">Enter your name and join the ever-growing list of amazing visitors.</p>
  </header>
  <div class="card">
    <div class="ct">Register <span>Yourself</span></div>
    <div class="row">
      <input type="text" id="ni" placeholder="Enter your name..." maxlength="80" autocomplete="off"/>
      <button onclick="sub()"><span class="shine"></span>Add Me</button>
    </div>
  </div>
  <div class="card">
    <div class="vh">
      <div class="ct" style="margin-bottom:0">All <span>Visitors</span></div>
      <div style="display:flex;gap:10px;align-items:center">
        <span class="cb" id="cb">0 visitors</span>
        <button class="rb" onclick="load()">Refresh</button>
      </div>
    </div>
    <div class="vl" id="vl"><div class="sp"></div></div>
  </div>
  <footer>Built with <span>Flask + DynamoDB + Terraform</span> - AWS Free Tier</footer>
</div>
<div id="toast"></div>
<script>
const C=['linear-gradient(135deg,#a29bfe,#6bcbff)','linear-gradient(135deg,#ff6b6b,#ffd93d)','linear-gradient(135deg,#55efc4,#00b894)','linear-gradient(135deg,#fd79a8,#e84393)','linear-gradient(135deg,#fdcb6e,#e17055)'];
function gc(s){let h=0;for(let c of s)h=(h*31+c.charCodeAt(0))&0xffffff;return C[h%C.length];}
function ta(iso){const d=(Date.now()-new Date(iso+'Z').getTime())/1000;if(d<60)return'just now';if(d<3600)return Math.floor(d/60)+'m ago';if(d<86400)return Math.floor(d/3600)+'h ago';return Math.floor(d/86400)+'d ago';}
function toast(m,e=false){const t=document.getElementById('toast');t.textContent=m;t.className='show'+(e?' err':'');setTimeout(()=>t.className='',3000);}
async function sub(){const i=document.getElementById('ni');const n=i.value.trim();if(!n){toast('Please enter your name!',true);return;}try{const r=await fetch('/submit',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name:n})});const d=await r.json();if(r.ok){toast(d.message);i.value='';load();}else toast(d.error||'Error',true);}catch{toast('Network error!',true);}}
async function load(){const l=document.getElementById('vl');l.innerHTML='<div class="sp"></div>';try{const r=await fetch('/visitors');const items=await r.json();document.getElementById('cb').textContent=items.length+(items.length===1?' visitor':' visitors');if(!items.length){l.innerHTML='<div class="empty">No visitors yet - be the first!</div>';return;}l.innerHTML='';items.forEach((v,i)=>{const ini=v.name.split(' ').map(w=>w[0]).join('').slice(0,2).toUpperCase();const el=document.createElement('div');el.className='vi';el.style.animationDelay=i*.05+'s';el.innerHTML='<div class="av" style="background:'+gc(v.name)+'">'+ini+'</div><div><div class="vn">'+v.name+'</div><div class="vt">'+ta(v.timestamp)+'</div></div><div class="vnum">#'+(items.length-i)+'</div>';l.appendChild(el);});}catch{l.innerHTML='<div class="empty">Could not load visitors.</div>';}}
document.getElementById('ni').addEventListener('keydown',e=>{if(e.key==='Enter')sub();});
load();
</script>
</body>
</html>
EOF

pip3 install flask boto3 gunicorn

cat > /etc/systemd/system/flaskapp.service << 'EOF'
[Unit]
Description=Flask Visitor App
After=network.target
[Service]
User=ec2-user
WorkingDirectory=/home/ec2-user/app
ExecStart=/usr/local/bin/gunicorn --workers 2 --bind 0.0.0.0:5000 app:app
Restart=always
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable flaskapp
systemctl start flaskapp

cat > /etc/nginx/conf.d/flaskapp.conf << 'EOF'
server {
    listen 80;
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

systemctl enable nginx
systemctl start nginx
systemctl restart nginx