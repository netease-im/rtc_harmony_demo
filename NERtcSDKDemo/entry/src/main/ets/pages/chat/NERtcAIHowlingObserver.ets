import { NERtcAudioProcessObserver } from "@nertc/nertc_sdk";
import RtcLogicModel from "./RtcLogicModel";

export class NERtcAIHowlingObserver implements NERtcAudioProcessObserver {

  private hintCount: number = 0
  private tag: string = 'NERtcAIHowlingObserver'
  private logicModel: RtcLogicModel|null = null

  constructor(loginModel: RtcLogicModel) {
    this.logicModel = loginModel
    console.info(this.tag, `NERtcAIHowlingObserver constructor ...`)
  }

  onAudioHasHowling(flag: boolean): void {
    this.hintCount++;
    console.info(this.tag, `onAudioHasHowling hint count: ${this.hintCount}`)
    this.logicModel?.GetDelegates().forEach(delegate => {
      if (delegate.aiHowling) {
        delegate.aiHowling(this.hintCount)
      }
    })
  }

}