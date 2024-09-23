

@Concurrent
export function testTransfer(data?: Uint8Array): void {
  console.info('taskpool_test', 'data.length:' + data?.length)
}