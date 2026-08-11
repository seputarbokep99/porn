#!/bin/bash

README_FILE="README.md"
TEMP_FILE="temp_links.txt"

# Mengambil baris di antara tag komentar
sed -n '/<!-- LINK_STATUS_START -->/,/<!-- LINK_STATUS_END -->/p' "$README_FILE" | grep -v '<!--' > "$TEMP_FILE"

NEW_BLOCK=""

while IFS= read -r line || [ -n "$line" ]; do
    [ -z "$line" ] && continue

    # Mencari pola URL http/https di dalam baris teks
    url=$(echo "$line" | grep -oE 'https?://[^ )]+' | head -n 1)

    if [ -z "$url" ]; then
        continue
    fi

    echo "Mengecek: $url"
    # Mengambil HTTP status code dengan timeout 10 detik
    status_code=$(curl -s -m 10 -o /dev/null -w "%{http_code}" "$url")

    # Menentukan warna berdasarkan status code
    if [ "$status_code" -eq 200 ]; then
        COLOR="brightgreen"
    elif [ "$status_code" -ge 300 ] && [ "$status_code" -lt 400 ]; then
        COLOR="yellow"
    elif [ "$status_code" -eq 000 ]; then
        COLOR="red"
        status_code="TIMEOUT"
    else
        COLOR="red"
    fi

    # Membuat format gambar badge Markdown
    badge="![HTTP $status_code](https://shields.io{status_code}-${COLOR})"

    # Menyusun teks hasil akhir
    NEW_BLOCK="${NEW_BLOCK}${badge} ${url}\n"
done < "$TEMP_FILE"

rm "$TEMP_FILE"

# Mengganti blok teks lama di README dengan yang baru
perl -i -0777 -pe "s/(<!-- LINK_STATUS_START -->\n)[\s\S]*?(\n<!-- LINK_STATUS_END -->)/\$1${NEW_BLOCK}<!-- LINK_STATUS_END -->/g" "$README_FILE"

echo "README.md berhasil diperbarui!"
