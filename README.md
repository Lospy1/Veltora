
# 🌌 Veltora

## 🇹🇷 Türkçe

**Veltora**, tamamen **sıfırdan** yazılmış küçük bir işletim sistemi projesidir.  
Şu anlık sadece boot edildiğinde mavi bir ekranda yazı gösteriyor ama bu, başlangıcın ta kendisi

Belki zamanla bir çekirdek, dosya sistemi ve arayüzle büyür…  
Takipte kalın! 🚀

---

## 🇺🇸 English

**Veltora** is a small operating system built completely **from scratch**.  
Currently, it only shows a message on a blue screen when booted but this is just the beginning 💡  

It may grow into a real OS one day, with a kernel, filesystem, and GUI.  
Stay tuned! 🌠

---

## ⚙️ Derleme / Build Instructions

### 🧩 Gerekli Paketler / Requirements

| Platform | Gerekli Paketler |
|-----------|------------------|
| **Termux (Android)** | `pkg install nasm` |
| **Ubuntu / Debian** | `sudo apt update && sudo apt install nasm` |
| **Arch / Manjaro** | `sudo pacman -S nasm` |
| **Fedora** | `sudo dnf install nasm` |
| **Windows** | [NASM indir](https://www.nasm.us/pub/nasm/releasebuilds/) ve PATH’e ekle |
| **macOS** | `brew install nasm` (Homebrew gerekli) |

---

### 🧠 Derleme / Build

``bash
nasm -f bin src/boot.asm -o kernel.bin ``

## 🇹🇷

**Veltora** henüz yeni bir proje olduğu için hatalarla karşılaşmanız olasıdır.
**Gelecek** güncellemelerde bu hatalar azaltılacak ve sistem daha kararlı hale gelecektir.

## 🇺🇸

Since **Veltora** is still a new project, you may encounter some bugs.
These issues will be reduced and the system will become more stable in **future** updates.
