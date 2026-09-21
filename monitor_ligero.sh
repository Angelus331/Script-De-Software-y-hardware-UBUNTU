#!/usr/bin/env bash

# Archivo de salida
REPORTE="reporte_t3micro_$(date +'%Y%m%d_%H%M%S').txt"

{
  echo "========================================================"
  echo "  REPORTE DEL SISTEMA (UBUNTU AWS EC2 - t3.micro)       "
  echo "  Fecha y hora: $(date)                                 "
  echo "========================================================"

  # 1. HARDWARE
  echo -e "\n[1. INFORMACIÓN DE HARDWARE]"
  
  echo "--- CPU (vCPU / Arquitectura) ---"
  grep -m 1 "model name" /proc/cpuinfo | sed 's/model name\t: /Modelo: /'
  echo "Núcleos lógicos detectados: $(grep -c '^processor' /proc/cpuinfo)"
  grep "cpu MHz" /proc/cpuinfo | head -n 1 | sed 's/cpu MHz\t\t: /Frecuencia base (MHz): /'

  echo -e "\n--- Memoria RAM y Swap (Física y Virtual) ---"
  free -m | awk 'NR==1{print "Tipo\tTotal(MB)\tUsado(MB)\tLibre(MB)"} NR>1{print $1 "\t" $2 "\t\t" $3 "\t\t" $4}'

  echo -e "\n--- Almacenamiento (Disco EBS / Particiones) ---"
  df -h -T -x tmpfs -x devtmpfs -x squashfs

  echo -e "\n--- Dispositivos / Hardware Virtual ---"
  echo "Tipo de virtualización: $(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo 'AWS EC2 Xen/KVM')"

  # 2. SOFTWARE Y PROCESOS
  echo -e "\n[2. INFORMACIÓN DE SOFTWARE]"

  echo "--- Sistema Operativo y Kernel ---"
  echo "Kernel: $(uname -r) ($(uname -m))"
  if [ -f /etc/os-release ]; then
    grep "PRETTY_NAME" /etc/os-release | cut -d= -f2 | tr -d '"'
  fi

  echo -e "\n--- Tiempo encendido y Carga del sistema ---"
  uptime

  echo -e "\n--- Top 5 Procesos con mayor uso de Memoria RAM ---"
  printf "%-8s %-7s %-6s %-6s %s\n" "USUARIO" "PID" "%CPU" "%MEM" "COMANDO"
  ps -eo user,pid,%cpu,%mem,comm --sort=-%mem | head -n 6 | tail -n 5

  echo -e "\n--- Top 5 Procesos con mayor uso de CPU ---"
  printf "%-8s %-7s %-6s %-6s %s\n" "USUARIO" "PID" "%CPU" "%MEM" "COMANDO"
  ps -eo user,pid,%cpu,%mem,comm --sort=-%cpu | head -n 6 | tail -n 5

  echo -e "\n--- Conteo total de tareas/procesos ---"
  echo "Total de procesos corriendo en el SO: $(ps -e --no-headers | wc -l)"

  echo -e "\n========================================================"
  echo "Reporte finalizado exitosamente."
  echo "========================================================"
} | tee "$REPORTE"

echo -e "\n[✔] Archivo generado: $REPORTE"