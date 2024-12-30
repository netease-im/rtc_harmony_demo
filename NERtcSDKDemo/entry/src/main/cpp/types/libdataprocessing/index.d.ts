
export class VideoCaptureProcessing {
  setFilePath(path: string);
  getNativeHandle(): bigint;
}

export class VideoRenderProcessing {
  getRenderHandle(xcomponentId: string): bigint;
  changeCanvasStyle(xcomponentId: string, mirror: number, scaleMode:number);
}