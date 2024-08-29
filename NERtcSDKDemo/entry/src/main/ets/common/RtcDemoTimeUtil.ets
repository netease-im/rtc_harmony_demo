import { intl } from '@kit.LocalizationKit';

export namespace RtcDemoTimeUtil {
  export function getFormattedTimestamp(): string {
    // let options: DateTimeOptions = { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit' , hour12: false, separator: '_'};
    let options: DateTimeOptions = { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit' , hour12: false};
    // let options: DateTimeOptions = { dateStyle: 'auto', timeStyle: 'auto', hourCycle: 'h24'};
    let currentTimestamp: number = Date.now(); // 获取当前时间戳
    let formattedTimestamp: string = new intl.DateTimeFormat('en-US', options).format(new Date(currentTimestamp)).replace(/[\/:,\s]/g, '_'); // 格式化时间戳为字符串
    return formattedTimestamp;
  }
}

export default RtcDemoTimeUtil