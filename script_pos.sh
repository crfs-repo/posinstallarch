#!/bin/bash

# Verifique se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, execute como root."
  exit
fi

# Atualizar o sistema
echo "Atualizando o sistema..."
pacman -Syu --noconfirm

# Instalar pacotes essenciais
echo "Instalando pacotes essenciais..."
pacman -S --noconfirm base-devel git vim wget curl

# Instalar drivers NVIDIA
echo "Instalando drivers NVIDIA..."
pacman -S --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings

# Atualizar o arquivo de configuração do GRUB
echo "Configurando GRUB para suporte à NVIDIA..."
GRUB_FILE="/etc/default/grub"
if grep -q "nvidia-drm.modeset=1" "$GRUB_FILE"; then
  echo "As configurações do GRUB já incluem nvidia-drm.modeset=1."
else
  sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia-drm.modeset=1 nvidia-drm.fbdev=1"/' "$GRUB_FILE"
  echo "Configurações adicionadas ao GRUB."
fi

# Gerar um novo arquivo de configuração do GRUB
echo "Gerando novo arquivo de configuração do GRUB..."
grub-mkconfig -o /boot/grub/grub.cfg

# Configurar carregamento antecipado dos módulos NVIDIA no mkinitcpio.conf
echo "Configurando o carregamento antecipado dos módulos NVIDIA no mkinitcpio.conf..."
MKINITCPIO_CONF="/etc/mkinitcpio.conf"
if grep -q "MODULES=(.*nvidia.*)" "$MKINITCPIO_CONF"; then
  echo "Os módulos NVIDIA já estão configurados em $MKINITCPIO_CONF."
else
  sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$MKINITCPIO_CONF"
  echo "Adicionado: MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)"
fi

# Remover o hook "kms" da linha HOOKS=() em mkinitcpio.conf
if grep -q "kms" "$MKINITCPIO_CONF"; then
  sed -i 's/\<kms\>//g' "$MKINITCPIO_CONF"
  echo "Hook 'kms' removido do arquivo mkinitcpio.conf."
fi

# Regenerar initramfs
echo "Regenerando o initramfs..."
mkinitcpio -P

# Instalar fontes e temas
echo "Instalando fontes e temas..."
pacman -S --noconfirm ttf-dejavu ttf-liberation noto-fonts papirus-icon-theme

# Adicionar suporte ao AUR (yay)
echo "Adicionando suporte ao AUR com yay..."
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg -si --noconfirm
cd ~

# Limpeza final
echo "Limpando o cache de pacotes..."
pacman -Sc --noconfirm

echo "Configuração pós-instalação concluída! Reinicie o sistema para aplicar as alterações."

