import socket# Створюємо TCP сокетs = socket.socket(socket.AF_INET, socket.SOCK_STREAM)# Біндимо на локальну петлю (тільки для цієї машини)
s.bind(('127.0.0.1', 8081))
s.listen(1)
print("Сервер запущено на 127.0.0.1:8081. Чекаю на підключення...")while True:
    conn, addr = s.accept()
    print(f"З'єднання від: {addr}")
    conn.sendall(b"Hello from Server!")
    conn.close()
