
export class VideoCaptureProcessing {
  setFilePath(path: string);
  getNativeHandle(): bigint;
}

export class VideoRenderProcessing {
  getRenderHandle(xcomponentId: string): bigint;
  changeCanvasStyle(xcomponentId: string, mirror: number, scaleMode:number);
}

export class VideoFuRender {
  enableBeauty(enable: boolean);
  setBundlePath(path: string);
  getNativeHandle(): bigint;
  setBeautyParam(key: string, value: number);
  setFilterParam(filter_name: string, filter_level: number);
}