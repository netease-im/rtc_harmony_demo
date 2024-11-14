export default class DemoUser {

  uid: bigint = BigInt(0);

  xComponentIdMain: string = ""
  xComponentIdSub?: string

  widthMain: string = '100%'
  heightMain: string = '100%'

  widthSub: string = '50%'
  heightSub: string = '50%'

  local: boolean = false;
  private streamType: number = 0 // 0: 主流， 1: 辅流
  private mirror: boolean = false //画布渲染镜像
  private scaleMode: number = 0 //画布缩放模式

  constructor(uid: bigint, local?: boolean) {
    this.uid = uid
    this.generatorMainCanvasId()
    if(local) {
      this.local = local
    }
  }

  /**
   * 当时用户选择的是不是主流？
   * @returns
   */
  userCheckIsMainStream(): boolean {
    return this.streamType == 0
  }

  /**
   * 用户切换至主流
   */
  turnToMainStream(): DemoUser {
    this.streamType = 0
    return this
  }

  /**
   * 用户切换至辅流
   */
  turnToSubStream(): DemoUser {
    this.streamType = 1
    return this
  }

  /**
   * 改变 scale mode.
   */
  changeScaleModeLoop(): DemoUser {
    this.scaleMode ++
    this.scaleMode = this.scaleMode % 2
    return this
  }

  switchCanvasMirror(): DemoUser {
    this.mirror = !this.mirror
    return this
  }

  getScaleMode(): number {
    return this.scaleMode
  }

  getCanvasMirror(): boolean {
    return this.mirror
  }

  generatorId(): string {
    return String(this.uid) + "_" + this.xComponentIdMain + this.xComponentIdSub
  }

  private generatorMainCanvasId(): void {
    this.xComponentIdMain = this.uid + '_main'
  }

  generatorSubCanvasId(): string {
    return this.uid + '_sub'
  }

  move(obj: Map<string,any>|DemoUser): void {
    if(!obj) return
    if(obj instanceof DemoUser) {
      for(const [key, value] of Object.entries(obj)) {
        this[key] = value
      }
    } else {
      obj.forEach((value, key) => {
        this[key] = value
      })
    }
  }

  static GeneratorSubCanvasId(uid: bigint): string {
    return uid + '_sub'
  }

  static newInstance(user: DemoUser): DemoUser {
    let instance = new DemoUser(user.uid)
    instance.move(user)
    return instance
  }

  static checkMapValid(obj: Map<string, any>): boolean {
    return obj.has('uid')
  }

}

