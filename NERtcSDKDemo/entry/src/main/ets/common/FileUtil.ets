

export class FileUtil {
  private static instance: FileUtil = new FileUtil();

  public static sharedInstance(): FileUtil {
    return FileUtil.instance;
  }

  public static getFileName(filePath: string): string {
    const parts = filePath.split('/');
    return parts[parts.length - 1];
  }
}