
export default class ARC4 {

  private sbox: Uint8Array = new Uint8Array(256)
  private sizeKey: number = 0;
  private prgaIndexA: number = 0;
  private prgaIndexB: number = 0;

  setKey(key: Uint8Array): void {
    this.prgaIndexA = 0;
    this.prgaIndexB = 0;
    this.sizeKey = key.length
    for (let i = 0; i < 256; i++) {
      this.sbox[i] = i;
    }
    this.ksa(key);
  }

  private ksa(key: Uint8Array): void {
    let j = 0;
    for (let i = 0; i < 256; i++) {
      j = (j + this.sbox[i] + key[i % this.sizeKey]) % 256;
      this.swap(this.sbox, i, j);
    }
  }

  private swap(data: Uint8Array, i: number, j: number): void {
    let temp = data[i];
    data[i] = data[j];
    data[j] = temp;
  }

  private prga(plaintext: Uint8Array, cipher: Uint8Array, size: number): void {
    for (let k = 0; k < size; k++) {
      this.prgaIndexA = (this.prgaIndexA + 1) % 256;
      this.prgaIndexB = (this.prgaIndexB + this.sbox[this.prgaIndexA]) % 256;
      this.swap(this.sbox, this.prgaIndexA, this.prgaIndexB);
      cipher[k] = this.sbox[(this.sbox[this.prgaIndexA] + this.sbox[this.prgaIndexB]) % 256] ^ plaintext[k];
    }
  }

  encrypt(plaintext: Uint8Array, ciphertext: Uint8Array, size: number): void {
    this.prga(plaintext, ciphertext, size);
  }
}