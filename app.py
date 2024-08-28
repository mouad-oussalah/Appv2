from flask import Flask, render_template, jsonify
from flask_sqlalchemy import SQLAlchemy
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import os
import time

app = Flask(__name__)

# Configuration de la base de données
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@db:5432/playersdb')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# Define Prometheus metrics
REQUEST_COUNT = Counter('app_api_players_request_count', 'Total number of requests to /api/players')
REQUEST_LATENCY = Histogram('app_api_players_request_latency_seconds', 'Request latency for /api/players')

class Player(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    position = db.Column(db.String(50), nullable=False)
    age = db.Column(db.Integer, nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'position': self.position,
            'age': self.age
        }

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/players')
@REQUEST_LATENCY.time()  # This decorator will measure the time taken by this function
def get_players():
    REQUEST_COUNT.inc()  # Increment the request counter
    try:
        players = Player.query.all()
        return jsonify([player.to_dict() for player in players])
    except Exception as e:
        app.logger.error(f"Erreur lors de la récupération des joueurs: {str(e)}")
        return jsonify({"error": "Une erreur s'est produite lors de la récupération des joueurs"}), 500

@app.route('/health')
def health_check():
    try:
        # Check database connection
        db.session.execute('SELECT 1')
        return jsonify({"status": "healthy"}), 200
    except Exception as e:
        app.logger.error(f"Health check failed: {str(e)}")
        return jsonify({"status": "unhealthy", "error": str(e)}), 500

@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)