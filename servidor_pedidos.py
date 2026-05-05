from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os
import time

# Configuração de Pasta (Windows vs Linux/Railway)
if os.name == 'nt':  # Se for Windows
    PASTA_PEDIDOS = r"C:\exe4_0\pedidos_entrada"
else:  # Se for Railway/Linux
    PASTA_PEDIDOS = "pedidos_entrada"

os.makedirs(PASTA_PEDIDOS, exist_ok=True)

class Handler(BaseHTTPRequestHandler):

    # RESOLVE O ERRO DE SEGURANÇA (CORS) - A "permissão" para o navegador
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    # TRATA O CARREGAMENTO DE IMAGENS, CARDÁPIO E LISTAGEM DE PEDIDOS
    def do_GET(self):
        try:
            caminho = self.path.split("?")[0]

            # Rota para o script baixar_pedidos.py buscar os arquivos
            if caminho == "/pedidos":
                arquivos = os.listdir(PASTA_PEDIDOS)
                lista = []
                for nome in arquivos:
                    if nome.endswith(".json"):
                        with open(os.path.join(PASTA_PEDIDOS, nome), "r", encoding="utf-8") as f:
                            lista.append(json.load(f))
                
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(json.dumps(lista).encode())
                return

            # Servir arquivos do site (index, imagens, json do cardápio)
            caminho_arquivo = caminho.lstrip("/")
            if not caminho_arquivo or caminho_arquivo == "":
                caminho_arquivo = "index.html"
            
            if os.path.exists(caminho_arquivo):
                with open(caminho_arquivo, "rb") as f:
                    self.send_response(200)
                    
                    # Identifica o tipo do arquivo para o navegador não bugar
                    if caminho_arquivo.endswith(".html"):
                        self.send_header("Content-Type", "text/html")
                    elif caminho_arquivo.endswith(".json"):
                        self.send_header("Content-Type", "application/json")
                    elif caminho_arquivo.endswith(".png"):
                        self.send_header("Content-Type", "image/png")
                    elif caminho_arquivo.endswith(".jpg") or caminho_arquivo.endswith(".jpeg"):
                        self.send_header("Content-Type", "image/jpeg")
                    
                    self.send_header("Access-Control-Allow-Origin", "*")
                    self.end_headers()
                    self.wfile.write(f.read())
                return
            else:
                self.send_response(404)
                self.end_headers()

        except Exception as e:
            print("Erro no GET:", e)
            self.send_response(500)
            self.end_headers()


    def do_DELETE(self):
        if self.path == "/limpar_pedidos":
            try:
                arquivos = os.listdir(PASTA_PEDIDOS)
                for nome in arquivos:
                    if nome.endswith(".json"):
                        os.remove(os.path.join(PASTA_PEDIDOS, nome))
                
                self.send_response(200)
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(b"Limpo")
            except Exception as e:
                self.send_response(500)
                self.end_headers()

    # RECEBE E SALVA O PEDIDO DO SITE
    def do_POST(self):
        if self.path == "/pedido":
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)

            try:
                pedido = json.loads(body)
                # Nome do arquivo com timestamp para ser único
                nome_arquivo = f"pedido_{int(time.time() * 1000)}.json"
                caminho_completo = os.path.join(PASTA_PEDIDOS, nome_arquivo)

                with open(caminho_completo, "w", encoding="utf-8") as f:
                    json.dump(pedido, f, indent=2, ensure_ascii=False)

                # RESPOSTA DE SUCESSO (Importante para o site não dar erro)
                self.send_response(200)
                self.send_header("Access-Control-Allow-Origin", "*")
                self.send_header("Content-Type", "text/plain")
                self.end_headers()
                self.wfile.write(b"OK")
                print(f"✅ Pedido recebido e salvo em: {caminho_completo}")

            except Exception as e:
                print("❌ Erro ao processar pedido:", e)
                self.send_response(500)
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(str(e).encode())

# Inicialização
PORT = int(os.environ.get("PORT", 5000))
server = HTTPServer(("0.0.0.0", PORT), Handler)
print(f"🚀 Servidor Sabores Cumbuca rodando na porta {PORT}")
server.serve_forever()