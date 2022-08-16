import React, { useState, ChangeEvent } from 'react'
import Alert from '@mui/material/Alert'
import Snackbar from '@mui/material/Snackbar'
import Stack from '@mui/material/Stack'
import Box from '@mui/material/Box'
import TextField from '@mui/material/TextField'
import MenuItem from '@mui/material/MenuItem'
import Paper from '@mui/material/Paper'
import { DesktopDatePicker } from '@mui/x-date-pickers/DesktopDatePicker'
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns'
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider'
import { styled } from '@mui/material/styles'

import getTime from 'date-fns/getTime'

import { deltaOptionContract } from '../common/ethProvider'
import ColorButton from '../Components/ColorButton'
import { formatDecimals } from '../utils/getOptionLists'

const Item = styled(Paper)(({ theme }) => ({
  backgroundColor:
    theme.palette.mode === 'dark' ? '#1A2027' : theme.palette.secondary.light,
  ...theme.typography.body2,
  padding: theme.spacing(2),
  textAlign: 'left',
  color: theme.palette.text.secondary,
  textTransform: 'none',
}))

const coins = [
  {
    value: 'CRO',
    label: 'CRO',
  },
  // {
  //   value: 'ETH',
  //   label: 'ETH',
  // },
]

export default function WriteOptions() {
  const [isOpenSnackBar, setOpenSnackBar] = useState<boolean>(false)
  const [currency, setCurrency] = useState<string>(coins[0].value)
  const [strikePrice, setStrikePrice] = useState<string>('')
  const [premium, setPremium] = useState<string>('')
  const [tokenAmount, setTokenAmount] = useState<string>('')
  const [expiry, setExpiry] = React.useState<Date | null>(new Date())

  const handleExpiryChange = (newValue: Date | null) => {
    setExpiry(newValue)
  }

  const handleChange = (event: ChangeEvent<HTMLInputElement>) => {
    setCurrency(event.target.value)
  }
  const handleStrikePriceChange = (event: ChangeEvent<HTMLInputElement>) => {
    setStrikePrice(event.target.value)
  }
  const handlePremiumChange = (event: ChangeEvent<HTMLInputElement>) => {
    setPremium(event.target.value)
  }
  const handleTknAmountChange = (event: ChangeEvent<HTMLInputElement>) => {
    setTokenAmount(event.target.value)
  }

  const handleSubmit = async () => {
    try {
      if (expiry) {
        const result = await deltaOptionContract.writeOption(
          currency,
          formatDecimals(strikePrice),
          formatDecimals(premium),
          getTime(expiry),
          formatDecimals(tokenAmount),
          {
            value: formatDecimals(tokenAmount),
          }
        )
      }
    } catch (error) {
      console.log(error)
    }
  }

  return (
    <div>
      <Box component={'form'} noValidate>
        <Stack>
          <Item>
            <TextField
              // id="outlined-select-currency"
              select
              label="token"
              value={currency}
              onChange={handleChange}
              helperText="Please select your want to write option coin"
            >
              {coins.map((option) => (
                <MenuItem key={option.value} value={option.value}>
                  {option.label}
                </MenuItem>
              ))}
            </TextField>
          </Item>

          <Item>
            <TextField
              label="strike price"
              type="number"
              value={strikePrice}
              helperText="Please write spot strike price"
              onChange={handleStrikePriceChange}
              InputLabelProps={{
                shrink: true,
              }}
            />
          </Item>

          <Item>
            <TextField
              label="premium"
              type="number"
              value={premium}
              helperText="Fee in contract token that option writer charges"
              onChange={handlePremiumChange}
              InputLabelProps={{
                shrink: true,
              }}
            />
          </Item>

          <Item>
            <LocalizationProvider dateAdapter={AdapterDateFns}>
              <DesktopDatePicker
                label="Date desktop"
                value={expiry}
                inputFormat="MM/dd/yyyy"
                onChange={handleExpiryChange}
                renderInput={(params) => <TextField {...params} />}
              />
            </LocalizationProvider>
          </Item>

          <Item>
            <TextField
              label="token amount"
              type="number"
              value={tokenAmount}
              helperText="How many tokens the contract is for"
              onChange={handleTknAmountChange}
              InputLabelProps={{
                shrink: true,
              }}
            />
          </Item>

          <Item>
            <ColorButton onClick={handleSubmit} variant="contained">
              Write Options
            </ColorButton>
          </Item>
        </Stack>
      </Box>

      <Snackbar
        open={isOpenSnackBar}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert variant="filled" severity="error">
          This is an error alert — check it out!
        </Alert>
      </Snackbar>
    </div>
  )
}
