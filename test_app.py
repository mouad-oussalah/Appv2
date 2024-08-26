import pytest
from app import app, db, Player

@pytest.fixture
def client():
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    client = app.test_client()

    with app.app_context():
        db.create_all()

    yield client

    with app.app_context():
        db.drop_all()

def test_index_route(client):
    response = client.get('/')
    assert response.status_code == 200

def test_get_players_route(client):
    with app.app_context():
        # Add a test player to the database
        test_player = Player(name='Test Player', position='Forward', age=25)
        db.session.add(test_player)
        db.session.commit()

    response = client.get('/api/players')
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert data[0]['name'] == 'Test Player'
    assert data[0]['position'] == 'Forward'
    assert data[0]['age'] == 25