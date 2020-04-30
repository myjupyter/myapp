## Тестовое задание:

1. скачать/собрать тарантул
2. запустить тестовое приложение
3. реализовать kv-хранилище доступное по http
4. выложить на гитхаб
5. задеплоить где-нибудь в публичном облаке

### API:

- POST /kv body: {key: "test", "value": {SOME ARBITRARY JSON}}
- PUT kv/{id} body: {"value": {SOME ARBITRARY JSON}}
- GET kv/{id}
- DELETE kv/{id}

- POST возвращает 409 если ключ уже существует,
- POST, PUT возвращают 400 если боди некорректное
- PUT, GET, DELETE возвращает 404 если такого ключа нет
- все операции логируются

### Тест:

- curl -i -X GET  ip_address:port/kv/{id}
- curl -i -X POST -d '{"key":"test", "value":{"something":["1", "2", "3"]}}' ip_address:port/kv
- curl -i -X PUT -d '{"value":{"something":["1", "2", "3"]}}' ip_address:port/kv/something
- curl -i -X DELETE ip_address:port/kv/{id}
