import firebase_admin
from firebase_admin import credentials, firestore
import os
import json
import time

# =========================
# ðŸ“ CAMINHOS DO SISTEMA
# =========================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

PASTA_SAIDA = r"C:\exe4_2\pedidos_entrada"
os.makedirs(PASTA_SAIDA, exist_ok=True)

# =========================
# ðŸ”‘ FIREBASE (CHAVE LOCAL)
# =========================

cred = credentials.Certificate(
    r"C:\exe4_2\firebase-key.json"
)

firebase_admin.initialize_app(cred)
db = firestore.client()

# =========================
# ðŸ’¾ SALVAR PEDIDO LOCAL
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
# ðŸ” LOOP PRINCIPAL
# =========================

print("ðŸš€ Iniciando monitor de pedidos...")

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

        print(f"âœ” Pedido baixado e removido: {doc.id}")

    if not encontrou:
        print("â³ Nenhum pedido novo...")

    time.sleep(5)

