"use shared"

@Sendable
export default class Handle {

  private static instance: Handle = new Handle()
  private data: number = 0
  static getInstance(): Handle {
    return Handle.instance
  }

  syncGet(): number {
    return this.data
  }

  syncSet(): void {
    this.data ++
  }

}