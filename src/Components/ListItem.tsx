import React from 'react'

import ListItemText from '@mui/material/ListItemText'
import ListItemAvatar from '@mui/material/ListItemAvatar'
import Avatar from '@mui/material/Avatar'

export interface IOptions {
  strike: string
  premium: string
  expiry: string
  amount: string
  exercised: boolean
  canceled: boolean
  id: number
  latestCost: string
  writer: string
  buyer: string
}

export default function ListItems({
  id,
  strike,
  amount,
  premium,
  expiry,
  exercised,
  canceled,
}: IOptions) {
  return (
    <>
      <ListItemAvatar>
        <Avatar src={require('../images/android-chrome-512x512.png')}></Avatar>
      </ListItemAvatar>
      <ListItemText primary="Id" secondary={id} />
      <ListItemText primary="Strike price" secondary={strike} />
      <ListItemText primary="Amount" secondary={amount} />
      <ListItemText primary="Premium" secondary={premium} />
      <ListItemText primary="Expiry" secondary={expiry} />
      <ListItemText primary="Exercised" secondary={exercised ? 'Yes' : 'No'} />
      <ListItemText primary="Canceled" secondary={canceled ? 'Yes' : 'No'} />
    </>
  )
}
