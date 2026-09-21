#!/usr/bin/env bash

# Archivo de salida con marca de tiempo
OUTPUT_FILE="inventario_$(hostname)_$(date +'%Y%m%d_%H%M%S').txt"

# Función para imprimir separadores
imprimir_cabecera() {
    echo "=================================================================" | tee -a "$OUTPUT_FILE"
    echo "  $1" | tee -a "$OUTPUT_FILE"
    echo "=================================================================" | tee -a "$OUTPUT_FILE"
}


imprimir_cabecera "INFORME DE HARDWARE Y SOFTWARE DEL SISTEMA"
echo "Host: $(hostname)" | tee -a "$OUTPUT_FILE"
echo "Fecha de captura: $(date)" | tee -a "$OUTPUT_FILE"

# 1. HARDWARE
imprimir_cabecera "1. COMPONENTES DE HARDWARE"

# CPU
echo -e "\n[+] Procesador (CPU):" | tee -a "$OUTPUT_FILE"
lscpu | grep -E "Model name|Arquitectura|Architecture|CPU\(s\):|Thread\(s\) per core|Core\(s\) per socket|CPU MHz|BogoMIPS" | tee -a "$OUTPUT_FILE"

# Memoria RAM y Swap
echo -e "\n[+] Memoria Física (RAM) y Swap:" | tee -a "$OUTPUT_FILE"
free -h | tee -a "$OUTPUT_FILE"

# Placa Base / Fabricante / BIOS
echo -e "\n[+] Sistema y Fabricante (DMI/BIOS):" | tee -a "$OUTPUT_FILE"
echo "Fabricante: $(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo 'No disponible')" | tee -a "$OUTPUT_FILE"
echo "Producto/Modelo: $(cat /sys/class/dmi/id/product_name 2>/dev/null || echo 'No disponible')" | tee -a "$OUTPUT_FILE"
echo "Versión BIOS: $(cat /sys/class/dmi/id/bios_version 2>/dev/null || echo 'No disponible')" | tee -a "$OUTPUT_FILE"

# Almacenamiento (Discos y Particiones)
echo -e "\n[+] Almacenamiento y Discos en Bloque:" | tee -a "$OUTPUT_FILE"
lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT | tee -a "$OUTPUT_FILE"

echo -e "\n[+] Uso de Espacio en Disco (Particiones Montadas):" | tee -a "$OUTPUT_FILE"
df -h -T -x tmpfs -x devtmpfs -x squashfs | tee -a "$OUTPUT_FILE"

# GPU / Tarjeta de Video
echo -e "\n[+] Dispositivos Gráficos (GPU):" | tee -a "$OUTPUT_FILE"
if command -v lspci &> /dev/null; then
    lspci | grep -E -i "vga|3d|display" | tee -a "$OUTPUT_FILE"
else
    echo "lspci no está instalado; consultando /sys..." | tee -a "$OUTPUT_FILE"
    ls -l /sys/class/drm/ 2>/dev/null | grep card | awk '{print $9}' | tee -a "$OUTPUT_FILE"
fi

# Tarjetas e Interfaces de Red
echo -e "\n[+] Dispositivos de Red:" | tee -a "$OUTPUT_FILE"
ip -br link show | tee -a "$OUTPUT_FILE"

# 2. SOFTWARE
imprimir_cabecera "2. COMPONENTES DE SOFTWARE"

# Sistema Operativo y Kernel
echo -e "\n[+] Sistema Operativo y Kernel:" | tee -a "$OUTPUT_FILE"
uname -srm | tee -a "$OUTPUT_FILE"
if [ -f /etc/os-release ]; then
    grep -E "PRETTY_NAME|VERSION_ID" /etc/os-release | tee -a "$OUTPUT_FILE"
fi

# Carga de trabajo y Uptime
echo -e "\n[+] Tiempo Encendido y Carga de Trabajo (Load Average):" | tee -a "$OUTPUT_FILE"
uptime | tee -a "$OUTPUT_FILE"

# Resumen de Procesos
echo -e "\n[+] Conteo Total de Procesos:" | tee -a "$OUTPUT_FILE"
echo "Total de tareas registradas: $(ps -e --no-headers | wc -l)" | tee -a "$OUTPUT_FILE"

# Top 5 Procesos por Consumo de Memoria RAM
echo -e "\n[+] Top 5 Procesos por Uso de RAM:" | tee -a "$OUTPUT_FILE"
printf "%-8s %-7s %-6s %-6s %s\n" "USUARIO" "PID" "%CPU" "%MEM" "COMANDO" | tee -a "$OUTPUT_FILE"
ps -eo user,pid,%cpu,%mem,comm --sort=-%mem | head -n 6 | tail -n 5 | tee -a "$OUTPUT_FILE"

# Top 5 Procesos por Consumo de CPU
echo -e "\n[+] Top 5 Procesos por Uso de CPU:" | tee -a "$OUTPUT_FILE"
printf "%-8s %-7s %-6s %-6s %s\n" "USUARIO" "PID" "%CPU" "%MEM" "COMANDO" | tee -a "$OUTPUT_FILE"
ps -eo user,pid,%cpu,%mem,comm --sort=-%cpu | head -n 6 | tail -n 5 | tee -a "$OUTPUT_FILE"

# Programas / Entornos Instalados Relevantes
echo -e "\n[+] Entornos y Servicios Base Detectados:" | tee -a "$OUTPUT_FILE"
for cmd in bash python3 perl gcc git docker systemd; do
    if command -v "$cmd" &> /dev/null; then
        echo "- $cmd: Instalado ($("$cmd" --version 2>/dev/null | head -n 1 || which "$cmd"))" | tee -a "$OUTPUT_FILE"
    else
        echo "- $cmd: No instalado" | tee -a "$OUTPUT_FILE"
    fi
done

imprimir_cabecera "INFORME COMPLETADO"
echo "Reporte guardado exitosamente en: $OUTPUT_FILE"
