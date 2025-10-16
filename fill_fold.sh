#!/bin/bash

if [ $# -ne 2 ]; then
	echo "Использование: $0 <папка> <порог %>"
	exit 1
fi

DIR=$1
THSH=$2
BACKUP_DIR="./backup"
N=0

if [ ! -d "$BACKUP_DIR" ]; then
	mkdir "$BACKUP_DIR"
fi

if [ ! -d "$DIR" ]; then
	echo "Ошибка: папка $DIR не существует"
	exit 1
fi

FILL=$(df "$DIR" | tail -1 | awk '{print $5}' | tr -d '%')

echo "Заполнение: $FILL%"

if [ "$FILL" -gt "$THSH" ]; then
	mkdir -p "./temporary_fl"
	while [ "$FILL" -gt "$THSH" ]; do
		OLD=$(find "$DIR" -maxdepth 1 -type f -printf "%T@ %p\n" | sort -n | head -1 | cut -d' ' -f2-)
		if [ -z "$OLD" ]; then
			echo "Нет файлов для архивации"
			break
		fi
		mv "$OLD" "./temporary_fl/"
		FILL=$(df "$DIR" | tail -1 | awk '{print $5}' | tr -d '%')
		((N++))
	done
	tar czf "$BACKUP_DIR/backup_$(date +%H%M%S).tar.gz" -C "." temporary_fl
	rm -rf "./temporary_fl"
	echo "Файлов архивировано: $N"
	echo "Заполнение папки после архивации: $FILL%"
fi
