#!/bin/bash

for i in {1..100}
do
  exec {fd}>/dev/null || { echo "Не вдалося відкрити файл номер $i"; exit 1; }
done

echo "Відкрито 100 файлів успішно"
