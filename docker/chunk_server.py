'''
chunked_server.py

This server chunks the return data, helpful for sending files that are growing at the time they are being requested.

DERIVED FROM: https://gist.githubusercontent.com/josiahcarlson/3250376/raw/11afcac83c766279ee6d8c541aa2c994458573e1/chunked_server_test.py

'''

import http.server 
import socketserver
import time
import os
import urllib.parse
import shutil

from http import HTTPStatus

global CHUNKING
CHUNKING = False

class ChunkingHTTPServer(socketserver.ThreadingMixIn,
                        http.server.HTTPServer):
    '''
    Basic chunk server
    '''

class ChunkingRequestHandler(http.server.SimpleHTTPRequestHandler):
    '''
    Nothing is terribly magical about this code, the only thing that you need
    to really do is tell the client that you're going to be using a chunked
    transfer encoding.
    '''
    def do_GET(self):
        """Serve a GET request."""
        global CHUNKING
        f = self.send_chunk_head()
        if f:
            try:
                avail = len(f.peek())
                while avail > 0:
                    if CHUNKING:
                        start = '%X\r\n'%(avail)
                        tosend = bytes(start, 'utf-8')
                        tosend += f.read(avail)
                        end = '\r\n'
                        tosend += bytes(end, 'utf-8')
                        #shutil.copyfileobj(tosend, self.wfile)
                        self.wfile.write(tosend)
                    else:
                        self.wfile.write(f.read(avail))
                    avail = len(f.peek())
                    if avail == 0:
                      time.sleep(1.0)
                      avail = len(f.peek())

                if CHUNKING:
                    chunk_trailer = bytes('0\r\n\r\n', 'utf-8')
                    self.wfile.write(chunk_trailer)
            finally:
                f.close()

    def send_chunk_head(self):
        """Taken from send_head in simpleHTTP, returns chunk header instead

        This sends the response code and MIME headers.

        Return value is either a file object (which has to be copied
        to the outputfile by the caller unless the command was HEAD,
        and must be closed by the caller under all circumstances), or
        None, in which case the caller has nothing further to do.

        """
        global CHUNKING
        path = self.translate_path(self.path)
        f = None
        if os.path.isdir(path):
            parts = urllib.parse.urlsplit(self.path)
            if not parts.path.endswith('/'):
                # redirect browser - doing basically what apache does
                self.send_response(HTTPStatus.MOVED_PERMANENTLY)
                new_parts = (parts[0], parts[1], parts[2] + '/',
                             parts[3], parts[4])
                new_url = urllib.parse.urlunsplit(new_parts)
                self.send_header("Location", new_url)
                self.end_headers()
                return None
            for index in "index.html", "index.htm":
                index = os.path.join(path, index)
                if os.path.exists(index):
                    path = index
                    break
            else:
                shutil.copyfileobj(self.list_directory(path), self.wfile)
                return None
        ctype = self.guess_type(path)
        try:
            f = open(path, 'rb')
        except OSError:
            self.send_error(HTTPStatus.NOT_FOUND, "File not found")
            return None
        try:
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-type", ctype)
            fs = os.fstat(f.fileno())
            #self.send_header("Content-Length", str(fs[6]))
            if CHUNKING:
                self.send_header('Transfer-Encoding', 'chunked')
            self.send_header("Last-Modified", self.date_time_string(fs.st_mtime))
            self.end_headers()
            return f
        except:
            f.close()
            raise

if __name__ == '__main__':
    server = ChunkingHTTPServer(('0.0.0.0', 5001), ChunkingRequestHandler)
    print("Starting server, use Ctrl-C to stop")
    server.serve_forever()

