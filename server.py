import iio
import json

from flask import Flask
app = Flask(__name__)

class Dev:
    def __init__(self):
        self.name = None
        self.channels = []

class Channel:
    def __init__(self):
        self.id = None
        self.attrs = []

class Attribute:
    def __init__(self):
        pass


@app.route('/')
def get_all_devices():
    ctx = iio.Context()
    devices = []
    if len(ctx.devices) == 0:
        return app.response_class(response=json.dumps("No devices detected"),status=404,mimetype='application/json')

    for device in ctx.devices:
        dev = Dev()
        dev.name = device.name
        for channel in device.channels:
            chan = Channel()
            chan.id = channel.id
            for attr, _ in channel.attrs.items():
                try:
                    attribute = Attribute()
                    setattr(attribute,channel.attrs[attr].name,channel.attrs[attr].value)
                    chan.attrs.append(attribute)
                except OSError as err:
                    print("ERROR: " + err.strerror + " (-" + str(err.errno) + ")")
                    return app.response_class(response=json.dumps("Error reading channel attributes"),status=404,mimetype='application/json')
            dev.channels.append(chan)
        devices.append(dev)
    data = json.dumps(devices, default=lambda o: o.__dict__, indent=4)
    response = app.response_class(response=data,status=200,mimetype='application/json')
    return response


if __name__ == '__main__':
    app.run(host='0.0.0.0',port=8110)