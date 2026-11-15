#!/bin/bash

MERAH='\033[1;31m'
HIJAU='\033[1;32m'
KUNING='\033[1;33m'
BIRU='\033[1;34m'
UNGU='\033[1;35m'
CYAN='\033[1;36m'
PUTIH='\033[1;37m'
NC='\033[0m' 

# File penyimpanan konfigurasi rahasia
CONFIG_FILE="$HOME/.domain_token.txt"

# Fungsi untuk memuat (load) konfigurasi jika file-nya ada
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        API_TOKEN=""
        GLOBAL_KEY=""
        ZONE_ID=""
        DOMAIN_UTAMA=""
    fi
}

load_config

ketik() {
    echo -e "$1" | while IFS= read -r -n1 char; do
        echo -n "$char"
        sleep 0.05
    done
    echo ""
}

while true; do
    clear

    toilet -f standard -F gay "DOMAIN"
    echo ""
    ketik "${CYAN}[+] Selamat Datang Di Menu Domain...${NC}"
    echo -e "${CYAN}[+] Waktu Login: $(date +'%d-%m-%Y | %H:%M:%S')${NC}"
    echo ""
    echo -e "${BIRU}------------------------------------------------${NC}"
    echo ""
    echo -e "${CYAN}============= PILIHAN FITUR UTAMA =============${NC}"
    echo -e "${HIJAU}1. Pelacak IP Domain (Metode Host)${NC}"
    echo -e "${HIJAU}2. Hosting / Buat Subdomain Cloudflare${NC}"
    echo -e "${HIJAU}3. Lihat / Hapus Subdomain Cloudflare${NC}"
    echo -e "${HIJAU}4. Setel / Ubah Token & Domain Cloudflare${NC}"
    echo -e "${MERAH}0. Exit Menu${NC}"
    echo -e "${CYAN}=================================================${NC}"
    
    # Indikator status konfigurasi singkat di layar
    if [ -z "$DOMAIN_UTAMA" ] || [ -z "$API_TOKEN" ]; then
        echo -e "${MERAH}[!] Status: Konfigurasi Cloudflare Belum Disetel! (Pilih Menu 4)${NC}"
    else
        echo -e "${HIJAU}[✓] Status: Terhubung ke Domain ($DOMAIN_UTAMA)${NC}"
    fi
    echo ""

    echo -ne "${UNGU} Ketikan pilihan anda : ${NC}"
    read pilihan

    case $pilihan in
        1)
            clear
            echo -e "\n${CYAN}[+] FITUR: PENCARI IP METODE PING${NC}"
            echo -e "${CYAN}=========================================${NC}"
            echo -e "${HIJAU} Masukkan Nama Domain Target${NC}"
            read -p "    (contoh: google.com): " domain_target
            
            if [ -z "$domain_target" ]; then
                echo -e "\n${MERAH}[!] Error: Nama domain tidak boleh kosong!${NC}"
            else
                echo -e "\n${HIJAU}[*] Mengirimkan paket ICMP (Ping) ke target...${NC}"
                sleep 1
                
                hasil_ip=$(ping -c 1 "$domain_target" 2>/dev/null | head -n 1 | awk -F '[()]' '{print $2}')
                
                if [ -z "$hasil_ip" ]; then
                    echo -e "${MERAH}[-] Gagal: Domain '$domain_target' tidak terjangkau/salah.${NC}"
                else
                    echo -e "\n${HIJAU}[+] SUKSES TERLACAK!${NC}"
                    echo -e "${HIJAU}    Target Host :${NC} $domain_target"
                    echo -e "${HIJAU}    Alamat IPv4 :${NC}"
                    echo -e "                  ${PUTIH}->${NC} ${HIJAU}$hasil_ip${NC}"
                fi
            fi
            echo -e "${CYAN}=========================================${NC}"
            echo -e "${UNGU}Tekan [Enter] untuk kembali...${NC}"
            read -s
            ;;
        2)
            if [ -z "$API_TOKEN" ] || [ -z "$ZONE_ID" ] || [ -z "$DOMAIN_UTAMA" ]; then
                echo -e "\n${MERAH}[!] Harap atur Token, Zone ID, dan Domain Utama terlebih dahulu di Menu 5!${NC}"
                sleep 2
                continue
            fi

            clear
            echo "======================================="
            echo "   CLOUDFLARE SUBDOMAIN CREATOR       "
            echo "======================================="
            echo ""

            read -p "Masukkan nama anak domain (misal: blog): " SUBDOMAIN
            if [ -z "$SUBDOMAIN" ]; then
                echo "Nama subdomain tidak boleh kosong!"
                read -p "Tekan [Enter] untuk kembali..."
                continue
            fi

            read -p "Masukkan Custom IP (misal: 192.168.1.1): " CUSTOM_IP
            if [ -z "$CUSTOM_IP" ]; then
                echo "IP tidak boleh kosong!"
                read -p "Tekan [Enter] untuk kembali..."
                continue
            fi

            read -p "Aktifkan Proxy Cloudflare? (y/n): " PROXY_CHOICE
            if [ "$PROXY_CHOICE" = "y" ] || [ "$PROXY_CHOICE" = "Y" ]; then
                PROXY=true
            else
                PROXY=false
            fi

            FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN_UTAMA}"
            echo ""
            echo "Sedang memproses ${FULL_DOMAIN} ke IP ${CUSTOM_IP}..."

            RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
                 -H "Authorization: Bearer ${API_TOKEN}" \
                 -H "Content-Type: application/json" \
                 --data "{\"type\":\"A\",\"name\":\"${FULL_DOMAIN}\",\"content\":\"${CUSTOM_IP}\",\"ttl\":120,\"proxied\":${PROXY}}")

            if [[ "$RESPONSE" != *'"success":true'* ]] && [ -n "$GLOBAL_KEY" ]; then
                RESPONSE_ALT=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
                     -H "X-Auth-Key: ${GLOBAL_KEY}" \
                     -H "Content-Type: application/json" \
                     --data "{\"type\":\"A\",\"name\":\"${FULL_DOMAIN}\",\"content\":\"${CUSTOM_IP}\",\"ttl\":120,\"proxied\":${PROXY}}")
                
                if [[ "$RESPONSE_ALT" == *'"success":true'* ]]; then
                    RESPONSE=$RESPONSE_ALT
                fi
            fi

            if [[ "$RESPONSE" == *'"success":true'* ]] || [[ "$RESPONSE_ALT" == *'"success":true'* ]]; then
                echo "======================================="
                echo "✅ BERHASIL! Anak domain telah dibuat."
                echo "Domain: ${FULL_DOMAIN}"
                echo "IP    : ${CUSTOM_IP}"
                echo "Proxy : ${PROXY}"
                echo "======================================="
            else
                echo "======================================="
                echo "❌ GAGAL! Respons Cloudflare ditolak."
                echo "---------------------------------------"
                echo "Analisis Respons Sistem:"
                echo "$RESPONSE" | grep -o '"message":"[^"]*"' | sed 's/"message":"/ - /;s/"//g'
                echo "======================================="
            fi
            
            echo -e "${UNGU}Tekan [Enter] untuk kembali...${NC}"
            read -s
            ;;
        3)
            if [ -z "$API_TOKEN" ] || [ -z "$ZONE_ID" ]; then
                echo -e "\n${MERAH}[!] Harap atur Token dan Zone ID terlebih dahulu di Menu 5!${NC}"
                sleep 2
                continue
            fi

            clear
            echo -e "${CYAN}=======================================${NC}"
            echo -e "${CYAN}            HAPUS SUBDOMAIN            ${NC}"
            echo -e "${CYAN}=======================================${NC}"
            echo "Memuat data dari Cloudflare..."

            LIST_RES=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?per_page=100" \
                -H "Authorization: Bearer ${API_TOKEN}" \
                -H "Content-Type: application/json")

            if [[ "$LIST_RES" != *'"success":true'* ]] && [ -n "$GLOBAL_KEY" ]; then
                LIST_RES=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?per_page=100" \
                    -H "X-Auth-Key: ${GLOBAL_KEY}" \
                    -H "Content-Type: application/json")
            fi

            if [[ "$LIST_RES" == *'"success":true'* ]]; then
                ID_ARRAY=($(echo "$LIST_RES" | grep -o '"id":"[^"]*"' | cut -d'"' -f4))
                NAME_ARRAY=($(echo "$LIST_RES" | grep -o '"name":"[^"]*"' | cut -d'"' -f4))
                
                if [ ${#NAME_ARRAY[@]} -eq 0 ]; then
                    echo "Tidak ada record domain yang ditemukan."
                else
                    echo -e "${CYAN}---------------------------------------${NC}"
                    for i in "${!NAME_ARRAY[@]}"; do echo "$((i+1)). ${NAME_ARRAY[$i]}"; done
                    echo -e "${KUNING}[*] Ketik nomor untuk menghapus.${NC}"
                    echo -e "${KUNING}[*] Atau langsung tekan [Enter] untuk kembali.${NC}"
                    echo -e "${CYAN}---------------------------------------${NC}"
                    read -p "Pilih aksi: " DEL_NUM
                    
                    if [ -z "$DEL_NUM" ]; then
                        echo "Kembali ke menu utama..."
                        sleep 1
                        continue
                    fi                    
                    if [[ "$DEL_NUM" =~ ^[0-9]+$ ]] && [ "$DEL_NUM" -ge 1 ] && [ "$DEL_NUM" -le "${#NAME_ARRAY[@]}" ]; then
                        TARGET_ID="${ID_ARRAY[$((DEL_NUM-1))]}"
                        TARGET_NAME="${NAME_ARRAY[$((DEL_NUM-1))]}"
                        
                        read -p "Apakah Anda yakin ingin menghapus $TARGET_NAME? (y/n): " CONFIRM
                        if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
                            DEL_RES=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${TARGET_ID}" \
                                -H "Authorization: Bearer ${API_TOKEN}" \
                                -H "Content-Type: application/json")
                                
                            if [[ "$DEL_RES" != *'"success":true'* ]] && [ -n "$GLOBAL_KEY" ]; then
                                DEL_RES=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${TARGET_ID}" \
                                    -H "X-Auth-Key: ${GLOBAL_KEY}" \
                                    -H "Content-Type: application/json")
                            fi
                            
                            [[ "$DEL_RES" == *'"success":true'* ]] && echo -e "${HIJAU}✅ Berhasil dihapus!${NC}" || echo -e "${MERAH}❌ Gagal menghapus!${NC}"
                        fi
                    else
                        echo -e "${MERAH}Pilihan salah!${NC}"
                    fi
                fi
            else
                echo -e "${MERAH}❌ Gagal memuat data Cloudflare.${NC}"
            fi
            echo -e "${UNGU}Tekan [Enter] untuk kembali...${NC}"
            read -s
            ;;
        4)
            clear
            echo -e "${CYAN}=======================================${NC}"
            echo -e "${CYAN}      PENGATURAN KREDENSIAL DOMAIN     ${NC}"
            echo -e "${CYAN}=======================================${NC}"
            
            echo -e "${KUNING}Nilai Saat Ini:${NC}"
            echo -e " - Domain Utama : ${PUTIH}${DOMAIN_UTAMA:-'(Belum diisi)'}${NC}"
            echo -e " - Zone ID      : ${PUTIH}${ZONE_ID:-'(Belum diisi)'}${NC}"
            echo -e " - API Token    : ${PUTIH}${API_TOKEN:-'(Belum diisi)'}${NC}"
            echo -e " - Global Key   : ${PUTIH}${GLOBAL_KEY:-'(Belum diisi)'}${NC}"
            echo -e "${CYAN}---------------------------------------${NC}"
            
            read -p "Ingin memperbarui konfigurasi ini? (y/n): " ubah_konfig
            if [[ "$ubah_konfig" =~ ^[Yy]$ ]]; then
                read -p "Masukkan Domain Utama (contoh: rizki18.my.id): " input_domain
                read -p "Masukkan Zone ID Cloudflare: " input_zone
                read -p "Masukkan API Token Cloudflare: " input_token
                read -p "Masukkan Global API Key (Opsional, boleh kosong): " input_global

                # Simpan ke file teks tersembunyi
                cat <<EOF > "$CONFIG_FILE"
DOMAIN_UTAMA="${input_domain:-$DOMAIN_UTAMA}"
ZONE_ID="${input_zone:-$ZONE_ID}"
API_TOKEN="${input_token:-$API_TOKEN}"
GLOBAL_KEY="${input_global:-$GLOBAL_KEY}"
EOF
                load_config
                echo -e "\n${HIJAU}✅ Konfigurasi berhasil disimpan!${NC}"
            fi
            echo -e "${UNGU}Tekan [Enter] untuk kembali...${NC}"
            read -s
            ;;
        0)
            clear
            echo -e "${CYAN}Terimakasih telah menggunakan script Rizki18${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${MERAH}[!] Pilihan tidak terdaftar. Silakan coba lagi.${NC}"
            sleep 1.5
            ;;
    esac
done
