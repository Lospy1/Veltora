# 📦 Veltora OS - v0.2.0-alpha 🚀

**Veltora OS v0.2.0-alpha yayınlandı!**

---

## 🎯 Yeni Özellikler

- ✅ **Masaüstü Ortamı** – Tam grafiksel arayüz  
- ✅ **Gerçek Fare Desteği** – Hareket ve tıklama  
- ✅ **Taskbar Sistemi** – Start butonu ve görev çubuğu  
- ✅ **Masaüstü İkonları** – My Computer, Documents, Browser, Settings  
- ✅ **Klavye Kontrolleri** – `ESC` çıkış, `Space` yenileme  
- ✅ **Dinamik Ekran** – Gerçek zamanlı grafik render

---

## 🔥 Kullanım

- 🖱️ Fare ile masaüstünde gezinebilirsiniz  
- ⌨️ `Space` tuşu ile ekranı temizleyin  
- 🚪 `ESC` tuşu ile sistemden çıkın  

---

# 🌌 Veltora

## 🇹🇷 Türkçe

**Veltora**, tamamen **sıfırdan** geliştirilen bir işletim sistemi projesidir.  
Proje Türkiyede Geliştirilip Yerli Ve milli bir Yazılımdır.

Gelecek sürümlerde, **dosya sistemi**, **çekirdek işlevleri** ve **grafiksel arayüz (GUI)** özellikleriyle büyümesi hedeflenmektedir.  

Bu proje tek bir geliştirici tarafından yürütüldüğü için bazı güncellemeler gecikebilir.  
Bu durumda kullanıcıların kendi sistemlerinde çekirdeği derlemeleri gerekebilir.  

Anlayışınız ve desteğiniz için teşekkürler.  
Takipte kalın. ⚙️  

---

## 🇺🇸 English

**Veltora** is an operating system project built completely **from scratch**.  
The project is developed in Turkiye and is a domestic and national software.

In future releases, it is planned to expand with features such as a **filesystem**, **kernel functions**, and a **graphical user interface (GUI)**.  

As this project is maintained by a single developer, kernel updates may occasionally be delayed.  
In such cases, users are encouraged to build the kernel manually on their systems.  

Thank you for your patience and support.  
Stay tuned. ⚙️  

---

## ⚙️ Derleme / Build Instructions

### 🧩 Gerekli Paketler / Requirements

| Platform | Gerekli Paketler |
|-----------|------------------|
| **Termux (Android)** | `pkg install nasm` |
| **Ubuntu / Debian** | `sudo apt update && sudo apt install nasm` |
| **Arch / Manjaro** | `sudo pacman -S nasm` |
| **Fedora** | `sudo dnf install nasm` |
| **Windows** | [NASM Download](https://www.nasm.us/pub/nasm/releasebuilds/) and add to PATH |
| **macOS** | `brew install nasm` (requires Homebrew) |

---

### 💻 Derleme / Build Command

```bash
bash tools/build.sh
