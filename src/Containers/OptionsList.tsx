import React, { useState, useEffect } from 'react'
import List from '@mui/material/List'
import ListItem from '@mui/material/ListItem'

import Divider from '@mui/material/Divider'
import ListItems, { IOptions } from '../Components/ListItem'

import ColorButton from '../Components/ColorButton'
import getOptionLists from '../utils/getOptionLists'
import { deltaOptionContract } from '../common/ethProvider'
import { formatDecimals } from '../utils/getOptionLists'

export default function OptionsList() {
  const [ethOptionLists, setEthOptionList] = useState<IOptions[]>([])

  useEffect(() => {
    getETHOptionLists()
  }, [])

  const getETHOptionLists = async () => {
    const { address, optionLists } = await getOptionLists()

    setEthOptionList(
      optionLists.filter(
        (option: IOptions) =>
          option.writer !== address && option.buyer !== address
      )
    )
  }

  const handleCancelOption = async (id: number, premium: string) => {
    if (deltaOptionContract) {
      await deltaOptionContract.buyOption('ETH', id, {
        value: formatDecimals(premium),
      })
    }
  }

  return ethOptionLists?.length ? (
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
              disabled={option.exercised || option.canceled}
              onClick={() => {
                handleCancelOption(option.id, option.premium)
              }}
            >
              Buy
            </ColorButton>
          </ListItem>
          {ethOptionLists.length - 1 !== index && (
            <Divider variant="fullWidth" component="li" />
          )}
        </span>
      ))}
    </List>
  ) : (
    <span className="w-full text-center">empty</span>
  )
}
