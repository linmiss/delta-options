import * as ethers from 'ethers'
import format from 'date-fns/format'
import { deltaOptionContract, signer } from '../common/ethProvider'
import { IOptions } from '../Components/ListItem'

export default async function getOptionLists() {
  try {
    let optionLists: IOptions[] = []
    let address = ''

    if (deltaOptionContract) {
      const formatOptions = (num: ethers.BigNumber) =>
        ethers.utils.formatUnits(num, 18)

      address = await signer?.getAddress()
      const data = await deltaOptionContract.getCroOptions()

      data?.forEach((item: any) => {
        optionLists.push({
          ...item,
          id: item.id.toNumber(),
          strike: formatOptions(item.strike),
          premium: formatOptions(item.premium),
          amount: formatOptions(item.amount),
          latestCost: formatOptions(item.latestCost),
          expiry: format(item.expiry.toNumber(), 'mm/dd/yyyy'),
        })
      })
    }

    return {
      address,
      optionLists,
    }
  } catch (error) {
    console.log('Get options lists error')
    console.error(error)
    return {
      address: '',
      optionLists: [],
    }
  }
}

export const formatDecimals = (num: string) => ethers.utils.parseEther(num)
