import React, { useState, useEffect } from 'react'
import List from '@mui/material/List'
import ListItem from '@mui/material/ListItem'
import Divider from '@mui/material/Divider'
import { deepOrange, blue, purple } from '@mui/material/colors'
import { formatDecimals } from '../utils/getOptionLists'

import ListItems, { IOptions } from '../Components/ListItem'
import { deltaOptionContract } from '../common/ethProvider'

import ColorButton from '../Components/ColorButton'
import getOptionLists from '../utils/getOptionLists'

export default function OwnedOptions() {
  const [ethOptionLists, setEthOptionList] = useState<IOptions[]>([])
  const [walletAddress, setWalletAddress] = useState<string>('')

  useEffect(() => {
    getETHOptionLists()
  }, [])

  const getETHOptionLists = async () => {
    const { address, optionLists } = await getOptionLists()
    console.log(optionLists)
    setWalletAddress(address)
    setEthOptionList(
      optionLists.filter(
        (option: IOptions) =>
          option.writer === address || option.buyer === address
      )
    )
  }

  const handleCancelOption = async (id: number) => {
    if (deltaOptionContract) {
      await deltaOptionContract.cancelOption('CRO', id)
    }
  }

  const handleExerciseOption = async (
    strike: string,
    amount: string,
    id: number
  ) => {
    try {
      if (deltaOptionContract) {
        const ethPrice = await deltaOptionContract.getUSDPrice('CRO')

        const latestCost = await deltaOptionContract.getLatestCost(
          formatDecimals(strike),
          ethPrice,
          formatDecimals(amount)
        )

        await deltaOptionContract.exercise('CRO', id, {
          value: latestCost,
        })
      }
    } catch (error) {
      console.log(error)
    }
  }

  const handleClickRetrieve = async (id: number) => {
    try {
      if (deltaOptionContract) {
        const ethPrice = await deltaOptionContract.retrieveExpiredFunds(
          'CRO',
          id
        )
      }
    } catch (error) {
      console.log(error)
    }
  }

  if (!ethOptionLists.length) {
    return (
      <div className="w-full text-center font-bold text-3xl mt-10">Empty</div>
    )
  }

  return (
    <List
      sx={{
        width: '100%',
        bgcolor: 'background.paper',
        boxShadow: '3px 3px 20px gray',
        borderRadius: '4px',
      }}
      className="bg-black"
    >
      {ethOptionLists.map((option: IOptions, index: number) => (
        <span key={option.id}>
          <ListItem>
            <ListItems {...option} />

            <ColorButton
              width="10%"
              variant="contained"
              sx={{
                marginLeft: '10px',
              }}
              disabled={
                option.exercised ||
                option.canceled ||
                option.writer !== walletAddress
              }
              bgcolor={deepOrange[500]}
              hovercolor={deepOrange[700]}
              onClick={() => {
                handleCancelOption(option.id)
              }}
            >
              Cancel
            </ColorButton>

            <ColorButton
              width="10%"
              variant="contained"
              sx={{
                marginLeft: '10px',
              }}
              disabled={
                option.exercised ||
                option.canceled ||
                option.buyer !== walletAddress
              }
              bgcolor={blue[500]}
              hovercolor={blue[700]}
              onClick={() => {
                handleExerciseOption(option.strike, option.amount, option.id)
              }}
            >
              Exercise
            </ColorButton>

            <ColorButton
              width="16%"
              variant="contained"
              sx={{
                marginLeft: '10px',
              }}
              disabled={
                option.exercised ||
                option.canceled ||
                option.writer !== walletAddress ||
                Date.now() <= new Date(option.expiry).getTime()
              }
              bgcolor={purple[500]}
              hovercolor={purple[700]}
              onClick={() => {
                handleClickRetrieve(option.id)
              }}
            >
              Retrieve Expired Fund
            </ColorButton>
          </ListItem>
          {ethOptionLists.length - 1 !== index && (
            <Divider variant="fullWidth" component="li" />
          )}
        </span>
      ))}
    </List>
  )
}
