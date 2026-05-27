import firebase_admin
from firebase_admin import credentials, firestore
import os
import json
import time

# =========================
# 📁 CAMINHOS DO SISTEMA
# =========================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

PASTA_SAIDA = r"C:\exe4_2\pedidos_entrada"
os.makedirs(PASTA_SAIDA, exist_ok=True)

# =========================
# 🔑 FIREBASE (CHAVE LOCAL)
# =========================

cred = credentials.Certificate(
    os.path.join(
        BASE_DIR,
        "sabores-cumbuca-firebase-adminsdk-fbsvc-ada6773814.json"
    )
)

firebase_admin.initialize_app(cred)
db = firestore.client()

# =========================
# 💾 SALVAR PEDIDO LOCAL
# =========================

def converter_firestore(obj):
    """Converte tipos do Firestore para JSON normal"""

    if isinstance(obj, dict):
        return {k: converter_firestore(v) for k, v in obj.items()}

    elif isinstance(obj, list):
        return [converter_firestore(v) for v in obj]

    # Firestore Timestamp -> string
    elif hasattr(obj, "isoformat"):
        return obj.isoformat()

    else:
        return obj


def salvar_arquivo(doc_id, data):
    caminho = os.path.join(PASTA_SAIDA, f"{doc_id}.json")

    data_limpa = converter_firestore(data)

    with open(caminho, "w", encoding="utf-8") as f:
        json.dump(data_limpa, f, ensure_ascii=False, indent=2)

# =========================
# 🔁 LOOP PRINCIPAL
# =========================

print("🚀 Iniciando monitor de pedidos...")

while True:
    docs = db.collection("pedidos").stream()

    encontrou = False

    for doc in docs:
        encontrou = True
        data = doc.to_dict()

        # salva localmente
        salvar_arquivo(doc.id, data)

        # remove do firebase (fila consumida)
        db.collection("pedidos").document(doc.id).delete()

        print(f"✔ Pedido baixado e removido: {doc.id}")

    if not encontrou:
        print("⏳ Nenhum pedido novo...")

    time.sleep(5)