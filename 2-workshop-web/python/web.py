from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
    return ('hola, soy una web app hecha con python Flask')

if __name__ == '__main__':
    app.run(port='5000',host='0.0.0.0')