import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { expect } from 'chai'
import { ethers } from 'hardhat'

describe('DeltaOption', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshopt in every test.
  async function deployDeltaOption() {
    // Contracts are deployed using the first signer/account by default
    const [owner, address0] = await ethers.getSigners()

    const deltaOption = await ethers.getContractFactory('DeltaOption')

    const deltaOptionContract = await deltaOption.deploy()

    await deltaOptionContract.deployed()

    return { owner, address0, deltaOptionContract }
  }

  const bigNumberFrom = ethers.BigNumber.from

  describe('Delta Options contract', function () {
    it('Should get option price', async function () {
      const { deltaOptionContract } = await loadFixture(deployDeltaOption)

      expect(
        await deltaOptionContract.getLatestCost(
          bigNumberFrom('1700000000000000000000'),
          bigNumberFrom('1800000000000000000000'),
          bigNumberFrom('1000000000000000000')
        )
      ).to.be.equal(bigNumberFrom('94444444'))
      expect(
        await deltaOptionContract.getLatestCost(
          bigNumberFrom('1700000000000000000000'),
          bigNumberFrom('1700000000000000000000'),
          bigNumberFrom('1000000000000000000')
        )
      ).to.be.equal(bigNumberFrom('100000000'))
      expect(
        await deltaOptionContract.getLatestCost(
          bigNumberFrom('1800000000000000000000'),
          bigNumberFrom('1700000000000000000000'),
          bigNumberFrom('1000000000000000000')
        )
      ).to.be.equal(bigNumberFrom('105882352'))
    })

    it('Get ETH price on Brand protocol feed', async () => {
      const { deltaOptionContract } = await loadFixture(deployDeltaOption)

      const price = await deltaOptionContract.getUSDPrice('ETH')
      console.log(price)

      expect(await deltaOptionContract.getUSDPrice('ETH')).to.be.equal(0)
    })
  })
})
