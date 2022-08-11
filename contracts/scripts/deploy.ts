import { ethers } from 'hardhat'

async function main() {
  const DeltaOptionContract = await ethers.getContractFactory('DeltaOption')
  const deltaOption = await DeltaOptionContract.deploy()

  await deltaOption.deployed()

  console.log(`DeltaOption deployed to:`, deltaOption.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
