import * as ethers from 'ethers'
import Web3Modal from 'web3modal'
import DeltaOption from '../contracts/DeltaOption.json'
import { DELTA_OPTION_LOCAL_ADDRESS } from '../constants/constant'
import { providerOptions } from './providerOptions'

export let provider: any
export let accounts: any
export let network: any
export let signer: any
export let deltaOptionContract: any

export const connectWallet = async () => {
  const web3Modal = new Web3Modal({
    cacheProvider: true, // optional
    providerOptions, // required
  })

  const web3Provider = await web3Modal.connect()

  provider = new ethers.providers.Web3Provider(web3Provider)
  accounts = await provider.listAccounts()
  network = await provider.getNetwork()

  signer = await provider.getSigner()

  deltaOptionContract = new ethers.Contract(
    DELTA_OPTION_LOCAL_ADDRESS,
    DeltaOption.abi,
    signer
  )

  return {
    web3Modal,
    provider,
    accounts,
    signer,
    network,
    deltaOptionContract,
  }
}
