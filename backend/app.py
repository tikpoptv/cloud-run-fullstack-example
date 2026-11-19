import os
from flask import Flask, jsonify, send_from_directory
STATIC = os.path.join(os.path.dirname(__file__), 'static')
app = Flask(__name__, static_folder=None)

@app.get('/api/hello')
def hello():
    return jsonify(ok=True, example='fullstack', flag=os.environ.get('TEST_FLAG'), has_database_url=bool(os.environ.get('DATABASE_URL')))

@app.get('/', defaults={'p': 'index.html'})
@app.get('/<path:p>')
def web(p):
    return send_from_directory(STATIC, p)
