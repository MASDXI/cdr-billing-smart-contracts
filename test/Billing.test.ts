import {
    time,
    loadFixture,
    mine,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
  import { expect } from "chai";
  import hre, { ethers } from "hardhat";
import { BytesLike, hexlify, randomBytes } from "ethers";
  
  describe("Lock", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployBilling() {
      // Contracts are deployed using the first signer/account by default
      const [owner, otherAccount] = await hre.ethers.getSigners();
  
      const BillingManager = await hre.ethers.getContractFactory("MockBillingManager");
      const billingManager = await BillingManager.deploy(1000);
  
      return { billingManager, owner, otherAccount };
    }
  
    describe("Call Detail Records Billing", function () {
      it("Should calculate correct cycle", async function () {
        const { billingManager, owner, otherAccount} = await loadFixture(deployBilling);
        const userId = randomBytes(16);
        const mockCDR = [
          1 /** SERVICE_TYPE */,
          1727971507 /** timestamp Thursday, October 3, 2024 4:05:07 PM */,
          1000 /** cost */,
          1000 /** balance */];
        const blocks = 2592000; // if blocktime is 1000ms 1 months will be around 2592000 blocks
        // @ts-ignore
        await billingManager.addCDR(userId, mockCDR);
        for (let index = 0; index < 12; index++) {
          const lastestBlockNumber = await ethers.provider.getBlockNumber();
          console.log(`📦 latest block at: #${lastestBlockNumber}`);
          await mine(blocks);
          console.log(`🔨 mining block: ${blocks}`);
          for (let index = 0; index < 5; index++) {
            // @ts-ignore
            await billingManager.addCDR(userId, mockCDR);
          }
          const latestBilling = (await billingManager.currentBillingCycleOf(userId)).toString();
          console.log(`🧾 latest billing cycle: #${latestBilling}`);
          console.log("CDRs list:");
          console.log(await billingManager["cdrOf(bytes16,uint256)"](userId,latestBilling));
        }
        const latestBilling = (await billingManager.currentBillingCycleOf(userId)).toString();
        await billingManager.removeCDR(userId, 3);
        console.log(await billingManager["cdrOf(bytes16,uint256)"](userId,latestBilling));
        console.log(await billingManager.outstandingBalanceOf(userId));
      });  

    });
});
  