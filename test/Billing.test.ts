import {
    time,
    loadFixture,
    mine,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
  import { expect } from "chai";
  import hre from "hardhat";
import { BytesLike, randomBytes } from "ethers";
  
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
  
    describe("Billing", function () {
      it("Should calculate correct cycle", async function () {
        const { billingManager, owner, otherAccount} = await loadFixture(deployBilling);
        const userId = randomBytes(16);
        const blocks = 7862400; // if blocktime is 1000ms 3 months will be around 7862400 blocks
        // @ts-ignore
        await billingManager.addCDR(userId, [
            1 /** SERVICE_TYPE */,
            1727971507 /** timestamp Thursday, October 3, 2024 4:05:07 PM */,
            1 /** cost */,
            1 /** balance */]);
        // @ts-ignore
        await billingManager.addCDR(userId, [1,1727971507,1,1]);
        console.log("🧾billing cycle:",(await billingManager.currentBillingCycleOf(userId)).toString());
        expect(await billingManager.currentBillingCycleOf(userId)).to.equal(0);
        console.log(await billingManager.currentSizeOfCDRs(userId));
        console.log(await billingManager["cdrOf(bytes16,uint256)"](userId,0));
        console.log(await billingManager["cdrOf(bytes16,uint256,uint8)"](userId,0,0));
        await mine(blocks);
        console.log(`⛏️  mining: ${blocks} blocks`);
        console.log(await billingManager["cdrOf(bytes16,uint256)"](userId,2));
        console.log("🧾billing cycle:",(await billingManager.currentBillingCycleOf(userId)).toString());
      });
  
        //   it("Should fail if the unlockTime is not in the future", async function () {
        //     // We don't use the fixture here because we want a different deployment
        //     const latestTime = await time.latest();
        //     const Lock = await hre.ethers.getContractFactory("Lock");
        //     await expect(Lock.deploy(latestTime, { value: 1 })).to.be.revertedWith(
        //       "Unlock time should be in the future"
        //     );
        //   });
    });
});
  