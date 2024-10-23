
import Handle from './Handle'

@Concurrent
export function testTransfer(data?: Uint8Array): void {
  console.info('taskpool_test', 'data.length:' + data?.length)
  Handle.getInstance().syncSet()
}