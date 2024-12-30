export default class DemoUser {

  uid: bigint = BigInt(0);

  xComponentIdMain: string = ""
  xComponentIdSub?: string
  xComponentIdThird?: string
  xComponentIdFourth?: string

  widthMain: string = '100%'
  heightMain: string = '100%'

  widthSub: string = '50%'
  heightSub: string = '50%'

  local: boolean = false;
  multiStream: "third" |"fourth" | null = null;

  private streamType: number = 0 // 0: 主流， 1: 辅流
  private mirror: boolean|null = null
  private scaleMode: number = 0 //画布缩放模式

  constructor(uid: bigint, local?: boolean, multiStream?: "third" |"fourth" | null) {
    this.uid = uid
    if(local) {
      this.local = local
    }
    if(multiStream){
      this.multiStream = multiStream
      if(multiStream == "third"){
        this.generatorThirdCanvasId()
      }else{
        this.generatorFourthCanvasId()
      }
    }else{
      this.generatorMainCanvasId()
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
    this.scaleMode = this.scaleMode % 3
    return this
  }

  switchCanvasMirror(): DemoUser {
    if (this.mirror == null) {
      this.mirror = false
    } else {
      this.mirror = !this.mirror
    }
    return this
  }

  getScaleMode(): number {
    return this.scaleMode
  }

  getCanvasMirror(): boolean|null {
    return this.mirror
  }

  generatorId(): string {
    let key: string = String(this.uid) + "_" + this.xComponentIdMain + this.xComponentIdSub
    if(this.multiStream != null) {
      key = key + this.multiStream;
    }

    return key
  }

  private generatorMainCanvasId(): void {
    this.xComponentIdMain = this.uid + '_main'
  }

  generatorThirdCanvasId(): string {
    this.xComponentIdThird = this.uid + '_third'
    return this.xComponentIdThird;
  }

  generatorFourthCanvasId(): string {
    this.xComponentIdFourth = this.uid + '_fourth'
    return this.xComponentIdFourth;
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
    let instance = new DemoUser(user.uid, user.local, user.multiStream)
    instance.move(user)
    return instance
  }

  static checkMapValid(obj: Map<string, any>): boolean {
    return obj.has('uid')
  }

}

