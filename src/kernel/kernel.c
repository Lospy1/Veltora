void kernel_main() {
    // VGA belleğine eriş
    unsigned char* video_memory = (unsigned char*)0xB8000;

    
    for(int i = 0; i < 80 * 25 * 2; i += 2) {
        video_memory[i] = ' ';
        video_memory[i + 1] = 0x1F;
    }
    
    // Mesaj yaz
    char* msg = "Veltora OS - C Kernel Active!";
    int pos = 0;
    
    for(int i = 0; msg[i] != '\0'; i++) {
        video_memory[pos] = msg[i];
        video_memory[pos + 1] = 0x1E;
        pos += 2;
    }
    
    while(1) {
      
    }
}
