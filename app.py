from flask import Flask, request, jsonify, render_template
import boto3
import uuid
from datetime import datetime
from botocore.exceptions import ClientError

app = Flask(__name__)

# DynamoDB setup
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
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

    item = {
        'id': str(uuid.uuid4()),
        'name': name,
        'timestamp': datetime.utcnow().isoformat()
    }
    table.put_item(Item=item)
    return jsonify({'message': f'Welcome, {name}! You have been registered.'}), 200

@app.route('/visitors', methods=['GET'])
def get_visitors():
    response = table.scan()
    items = response.get('Items', [])
    items.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
    return jsonify(items), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
