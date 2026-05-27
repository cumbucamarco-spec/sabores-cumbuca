from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
import time
import traceback

# Configuração de Pasta
if os.name == 'nt':
    PASTA_PEDIDOS = r"C:\exe4_2\pedidos_entrada"
else:
    PASTA_PEDIDOS = "pedidos_entrada"

os.makedirs(PASTA_PEDIDOS, exist_ok=True)

class Handler(BaseHTTPRequestHandler):

    # CORS GLOBAL
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, GET, OPTIONS, DELETE")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        super().end_headers()

    # PREFLIGHT CORS
    def do_OPTIONS(self):
        print("✅ OPTIONS:", self.path)

        self.send_response(200)
        self.end_headers()

    # GET
    def do_GET(self):

        try:

            caminho = self.path.split("?")[0]

            print("GET:", caminho)

            if caminho == "/pedidos":

                arquivos = os.listdir(PASTA_PEDIDOS)

                lista = []

                for nome in arquivos:
                    if nome.endswith(".json"):
                        try:
                            with open(os.path.join(PASTA_PEDIDOS, nome), "r", encoding="utf-8") as f:
                                lista.append(json.load(f))
                        except Exception as e:
                            print(f"⚠️ JSON corrompido ignorado: {nome}")

                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()

                self.wfile.write(json.dumps(lista).encode())

                return

            self.send_response(404)
            self.end_headers()

        except Exception:

            print("❌ ERRO GET")
            traceback.print_exc()

            self.send_response(500)
            self.end_headers()

    # DELETE
    def do_DELETE(self):

        try:

            if self.path == "/limpar_pedidos":

                arquivos = os.listdir(PASTA_PEDIDOS)

                for nome in arquivos:

                    if nome.endswith(".json"):

                        os.remove(os.path.join(PASTA_PEDIDOS, nome))

                self.send_response(200)
                self.end_headers()

                self.wfile.write(b"Limpo")

                print("🗑️ Pedidos removidos")

        except Exception:

            traceback.print_exc()

            self.send_response(500)
            self.end_headers()

    # POST
    def do_POST(self):

        print("POST:", self.path)

        if self.path == "/pedido":

            try:

                content_length = int(self.headers.get('Content-Length', 0))

                body = self.rfile.read(content_length)

                pedido = json.loads(body)

                nome_arquivo = f"pedido_{int(time.time() * 1000)}.json"

                caminho_completo = os.path.join(PASTA_PEDIDOS, nome_arquivo)

                with open(caminho_completo, "w", encoding="utf-8") as f:

                    json.dump(pedido, f, indent=2, ensure_ascii=False)

                self.send_response(200)
                self.send_header("Content-Type", "text/plain")
                self.end_headers()

                self.wfile.write(b"OK")

                print(f"✅ Pedido salvo: {caminho_completo}")

            except Exception:

                print("❌ ERRO POST")
                traceback.print_exc()

                self.send_response(500)
                self.end_headers()

                self.wfile.write(b"Erro interno")


PORT = int(os.environ.get("PORT", 5001))

server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)

print(f"🚀 Servidor rodando na porta {PORT}")

server.serve_forever()