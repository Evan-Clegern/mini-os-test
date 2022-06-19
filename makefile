test_boot.bin:
	nasm -felf64 boot.asm -o boot.o -Ox
	nasm -felf64 kernel.asm -o kernel.o -Ox
	nasm -felf64 os_util.asm -o os_util.o -Ox
	ld -T linker.ld -o test_boot.bin -O2 -nostdlib boot.o os_util.o kernel.o
	@if grub-file --is-x86-multiboot test_boot.bin; then echo "Compiled properly"; else echo "Failed to compile properly!"; fi
	rm -f boot.o kernel.o os_util.o cmp/boot/test_boot.bin myos.iso
	mv test_boot.bin cmp/boot/
	@grub-mkrescue --compress=xz --md5 --xattr -r -quiet -o myos.iso cmp


# -ffreestanding
