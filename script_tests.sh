#!/bin/bash

BASIC_SCRIPT="./fill_fold.sh"
TESTS_DIR="./tests"
LOG_DIR_NAME="log"
DISK_IMAGE="./new_virtual_disk.img"

dd if=/dev/zero of="$DISK_IMAGE" bs=1G count=1 status=none
mkfs -t ext4 "$DISK_IMAGE" > /dev/null 2>&1

mkdir -p "$TESTS_DIR"

generate_logs() {
    local case_dir="$1"
    for j in {1..20}; do
        dd if=/dev/zero of="$case_dir/file_$j.bin" bs=1M count=40 status=none
    done
}

check_case() {
    local case_dir="$1"
    local thsh="$2"

    mkdir -p "$case_dir/$LOG_DIR_NAME"

    mount -o loop "$DISK_IMAGE" "$case_dir/$LOG_DIR_NAME"
    generate_logs "$case_dir/$LOG_DIR_NAME"

    old_size=$(du -sb "$case_dir/$LOG_DIR_NAME" | cut -f1)

    echo "Проверка теста: $case_dir"
    bash "$BASIC_SCRIPT" "$case_dir/$LOG_DIR_NAME" "$thsh"

    new_size=$(du -sb "$case_dir/$LOG_DIR_NAME" | cut -f1)
    rm -rf "$case_dir/$LOG_DIR_NAME"/*

    umount "$case_dir/$LOG_DIR_NAME"
    disk_size=$(stat -c %s "$DISK_IMAGE")
    expected_size=$(( disk_size * thsh / 100 ))

    if [ "$new_size" -le "$expected_size" ]; then
        echo "Тест $case_dir: OK"
        echo "Старый размер: $(numfmt --to=iec $old_size), новый размер: $(numfmt --to=iec $new_size), порог: $thsh%"
		echo ""
    else
        echo "Тест $case_dir: FAIL"
        echo "Старый размер: $(numfmt --to=iec $old_size), новый размер: $(numfmt --to=iec $new_size), порог: $thsh%"
		echo ""
    fi
}

for i in 1 2 3 4; do
    case_dir="$TESTS_DIR/$i"
    rm -rf "$case_dir"
    mkdir -p "$case_dir"
    thsh=$((50 + i*10))
    check_case "$case_dir" "$thsh"
done

rm -f "$DISK_IMAGE"
