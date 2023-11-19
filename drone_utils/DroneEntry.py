#!/usr/bin/env python3


from flask import Flask, Response, send_from_directory
from flask_cors import CORS

from CameraDelegate import CameraDelegate


app = Flask(__name__)
CORS(app)

def camera_generator(delegate):
    while True:
        frame = delegate.get_current_frame()
        if frame is None:
            frame = b""
        response = frame#b'--frame\r\nContent-Type: image/jpeg\r\n\r\n' + frame + b'\r\n'
        yield response

@app.route('/drone_cam')
def drone_cam():
    hls_file_path = './stream/'
    #cam_delegate = CameraDelegate()
    #cam_delegate.start_stream()
    #cam_gen = camera_generator(cam_delegate)
    hls_content = f"""
    #EXTM3U
    #EXT-X-VERSION:3
    #EXT-X-STREAM-INF:BANDWIDTH=1500000,RESOLUTION=1280x720
    {hls_file_path}/stream.m3u8
    """

    return send_from_directory(hls_file_path, 'stream.m3u8')
    #hls_content=f"{hls_file_path/stream.m3u8}"
    #return Response(hls_content, mimetype='application/vnd.apple.mpegurl')


@app.route('/<filename>')
def drone_frame(filename):
    hls_file_path = './stream'
    return send_from_directory(hls_file_path, filename)

def main():
    app.run(host='0.0.0.0', debug=True, port=5000, threaded=True)

if __name__ == '__main__':
    main()
