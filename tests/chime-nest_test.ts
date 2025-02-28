import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test sleep session management",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // Start sleep session
    let block = chain.mineBlock([
      Tx.contractCall('chime-nest', 'start-sleep', [], deployer.address)
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Verify active session
    let response = chain.callReadOnlyFn('chime-nest', 'get-session-info', [], deployer.address);
    let sessionData = response.result.expectOk().expectSome();
    assertEquals(sessionData['active'], true);
    
    // Try starting another session (should fail)
    block = chain.mineBlock([
      Tx.contractCall('chime-nest', 'start-sleep', [], deployer.address)
    ]);
    block.receipts[0].result.expectErr().expectUint(103); // err-session-exists
    
    // End session with rating
    block = chain.mineBlock([
      Tx.contractCall('chime-nest', 'end-sleep', [types.uint(8)], deployer.address)
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Verify session ended
    response = chain.callReadOnlyFn('chime-nest', 'get-session-info', [], deployer.address);
    sessionData = response.result.expectOk().expectSome();
    assertEquals(sessionData['active'], false);
    assertEquals(sessionData['quality'], 8);
  }
});

Clarinet.test({
  name: "Test sound preferences and alarms",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // Set sound preferences
    let block = chain.mineBlock([
      Tx.contractCall('chime-nest', 'set-sound-preference', 
        [types.ascii("rain"), types.uint(70)], 
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Verify sound preferences
    let response = chain.callReadOnlyFn('chime-nest', 'get-sound-preferences', [], wallet1.address);
    let prefData = response.result.expectOk().expectSome();
    assertEquals(prefData['sound-type'], "rain");
    assertEquals(prefData['volume'], 70);
    
    // Set invalid volume (should fail)
    block = chain.mineBlock([
      Tx.contractCall('chime-nest', 'set-sound-preference',
        [types.ascii("rain"), types.uint(101)],
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectErr().expectUint(104); // err-invalid-volume
    
    // Set alarm
    block = chain.mineBlock([
      Tx.contractCall('chime-nest', 'set-alarm',
        [types.uint(7), types.uint(30), types.ascii("gradual")],
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Verify alarm settings
    response = chain.callReadOnlyFn('chime-nest', 'get-alarm', [], wallet1.address);
    let alarmData = response.result.expectOk().expectSome();
    assertEquals(alarmData['hour'], 7);
    assertEquals(alarmData['minute'], 30);
    assertEquals(alarmData['type'], "gradual");
  }
});
