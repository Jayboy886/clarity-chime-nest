[Previous test content with additional test cases for new functionality]

Clarinet.test({
  name: "Test analytics and validation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // Test invalid alarm time
    let block = chain.mineBlock([
      Tx.contractCall('chime-nest', 'set-alarm',
        [types.uint(24), types.uint(30), types.ascii("gradual")],
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectErr().expectUint(105);
    
    // Test sleep analytics
    block = chain.mineBlock([
      Tx.contractCall('chime-nest', 'start-sleep', [], wallet1.address)
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Mine some blocks to simulate sleep time
    chain.mineEmptyBlockUntil(chain.blockHeight + 100);
    
    block = chain.mineBlock([
      Tx.contractCall('chime-nest', 'end-sleep', [types.uint(8)], wallet1.address)
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Check stats
    let response = chain.callReadOnlyFn('chime-nest', 'get-user-stats', [], wallet1.address);
    let stats = response.result.expectOk().expectSome();
    assertEquals(stats['total-sessions'], 1);
    assertEquals(stats['avg-quality'], 8);
  }
});
