import urllib.request
import json

def test_api():
    base = 'http://127.0.0.1:8000'
    print("=" * 60)
    print("ПРОВЕРКА РАБОТОСПОСОБНОСТИ СЕРВЕРА (LIVE API TEST)")
    print("=" * 60)
    
    # 1. Health
    with urllib.request.urlopen(f'{base}/health') as r:
        health = json.loads(r.read().decode())
        print(f"[OK] 1. Статус сервера: {health['status']} ({health['service']})")

    # 2. Dashboard summary
    with urllib.request.urlopen(f'{base}/api/v1/analytics/dashboard-summary') as r:
        summary = json.loads(r.read().decode())
        print(f"[OK] 2. Главный экран: Баланс {summary['currency_symbol']}{summary['total_balance']:,.0f} (+{summary['balance_change_percentage']}%)")
        print(f"     Инсайт: «{summary['active_ai_insight']['title']}»")
        for m in summary['metric_cards']:
            print(f"     - {m['label']}: ${m['amount']:,.0f}")

    # 3. Ingest SMS
    sms_payload = {
        'raw_text': 'Oplata CLICK: 45 000 UZS, Karta *4821, Mesto: Korzinka. Balans: 1 200 000 UZS',
        'source': 'sms'
    }
    data = json.dumps(sms_payload).encode('utf-8')
    req = urllib.request.Request(f'{base}/api/v1/transactions/ingest', data=data, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req) as r:
        res = json.loads(r.read().decode())
        tx = res['transaction']
        print(f"[OK] 3. Парсер транзакций (SMS Click):")
        print(f"     Сумма: {tx['amount']:,.0f} {tx['currency']}")
        print(f"     Мерчант: {tx['merchant']}")
        print(f"     Карта: *{tx['card_last4']}")
        print(f"     Статус: {tx['status']} (Confidence: {tx['confidence_score'] * 100:.0f}%)")

    # 4. Ask AI Assistant
    ai_payload = {'query': 'Can I afford a $700 laptop?'}
    ai_data = json.dumps(ai_payload).encode('utf-8')
    ai_req = urllib.request.Request(f'{base}/api/v1/ai/chat', data=ai_data, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(ai_req) as r:
        ai_res = json.loads(r.read().decode())
        print(f"[OK] 4. AI-Ассистент (Вопрос: «Can I afford a $700 laptop?»):")
        print(f"     Заголовок: {ai_res['title']}")
        print(f"     Ответ: {ai_res['reply']}")

    # 5. Cards API
    with urllib.request.urlopen(f'{base}/api/v1/cards/') as r:
        cards_res = json.loads(r.read().decode())
        print(f"[OK] 5. Карты пользователя: {cards_res['count']} шт.")
        for c in cards_res['cards']:
            print(f"     - {c['bank_name']} ({c['card_type']}): {c['masked_number']}")

    print("=" * 60)
    print("ВСЕ 5 ПРОВЕРОК ПРОЙДЕНЫ УСПЕШНО НА 100%!")
    print("=" * 60)

if __name__ == '__main__':
    test_api()
