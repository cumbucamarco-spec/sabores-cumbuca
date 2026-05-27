import firebase_admin
from firebase_admin import credentials, firestore
import os
import json
import time

# =========================
# 📁 CAMINHOS DO SISTEMA
# =========================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# Ajustado para a pasta que o sistema antigo usava
PASTA_SAIDA = r"C:\exe4_2\pedidos_entrada" 
os.makedirs(PASTA_SAIDA, exist_ok=True)

# =========================
# 🔑 FIREBASE
# =========================

cred = credentials.Certificate(
    os.path.join(BASE_DIR, "sabores-cumbuca-firebase-adminsdk-fbsvc-ada6773814.json")
)

firebase_admin.initialize_app(cred)
db = firestore.client()

# =========================
# ⚙️ FUNÇÕES DE TRATAMENTO
# =========================

def processar_dados(data):
    """Limpa e formata os dados para o padrão do sistema antigo"""
    
    # 1. Converter o campo 'itens' que vem como string JSON
    if "itens" in data and isinstance(data["itens"], str):
        try:
            data["itens"] = json.loads(data["itens"])
        except json.JSONDecodeError:
            pass # Mantém como string se falhar
            
    # 2. Remover campos que o sistema antigo não reconhece (ex: campo 'data' do firebase)
    campos_para_remover = ['data']
    for campo in campos_para_remover:
        if campo in data:
            del data[campo]
            
    return data

# =========================
# 🔁 LOOP PRINCIPAL
# =========================

print("🚀 Sincronizador Firebase -> Local Ativo!")

while True:
    try:
        docs = db.collection("pedidos").stream()
        encontrou = False

        for doc in docs:
            encontrou = True
            pedido_raw = doc.to_dict()
            
            # Formata os dados
            pedido_final = processar_dados(pedido_raw)
            
            # Gerar nome do arquivo no padrão antigo: pedido_NOME_TIMESTAMP.json
            nome_cliente = pedido_final.get('cliente', 'cliente').replace(" ", "_")
            timestamp = int(time.time() * 1000)
            nome_arquivo = f"pedido_{nome_cliente}_{timestamp}.json"
            
            # Salvar
            caminho_completo = os.path.join(PASTA_SAIDA, nome_arquivo)
            with open(caminho_completo, "w", encoding="utf-8") as f:
                json.dump(pedido_final, f, indent=2, ensure_ascii=False)
            
            # Remover do Firebase após salvar com sucesso
            db.collection("pedidos").document(doc.id).delete()
            
            print(f"✅ Pedido de {nome_cliente} salvo como {nome_arquivo}")

        if not encontrou:
            print(f"[{time.strftime('%H:%M:%S')}] Nenhum pedido novo...")

    except Exception as e:
        print(f"❌ Erro na sincronização: {e}")

    time.sleep(10) # Intervalo para não sobrecarregar