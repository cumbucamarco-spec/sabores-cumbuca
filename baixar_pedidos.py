import requests
import json
import os
import time

PASTA_LOCAL = r"C:\exe4_0\pedidos_entrada"
os.makedirs(PASTA_LOCAL, exist_ok=True)

URL_BASE = "https://cumbuca-servidor-production.up.railway.app"

def baixar_e_limpar():
    print(f"[{time.strftime('%H:%M:%S')}] Verificando novos pedidos...")
    try:
        # 1. Tenta baixar os pedidos
        response = requests.get(f"{URL_BASE}/pedidos", timeout=10)
        
        if response.status_code == 200:
            pedidos = response.json()
            
            if not pedidos:
                return

            # 2. Salva os pedidos no seu PC
            for pedido in pedidos:
                timestamp = int(time.time() * 1000)
                nome_cliente = pedido.get('cliente', 'cliente').replace(" ", "_")
                nome_arquivo = f"pedido_{nome_cliente}_{timestamp}.json"
                
                with open(os.path.join(PASTA_LOCAL, nome_arquivo), "w", encoding="utf-8") as f:
                    json.dump(pedido, f, indent=2, ensure_ascii=False)
                
                print(f"✅ Pedido de {nome_cliente} salvo!")

            # 3. Manda o comando para o Railway apagar os pedidos que já baixamos
            requests.delete(f"{URL_BASE}/limpar_pedidos", timeout=10)
            print("🧹 Servidor limpo para os próximos pedidos.")
            
        else:
            print(f"❌ Erro no servidor: {response.status_code}")

    except Exception as e:
        print(f"⚠️ Erro: {e}")

if __name__ == "__main__":
    print("Sincronizador Sabores Cumbuca Ativo!")
    while True:
        baixar_e_limpar()
        time.sleep(30)