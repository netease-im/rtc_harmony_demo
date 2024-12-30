
export function injectJsonValue(obj: object, json: string): void {
  try {
    let result: any = JSON.parse(json)
    for (let key in result) {
      console.log(`${key}: ${result[key]}`)
      obj[key] = result[key]
    }
  } catch (e) {
    console.error("parse json failed, reason:" + JSON.stringify(e))
  }
}

export function GetJsonValue(obj: object, name: string): string {
  return obj[name];
}
