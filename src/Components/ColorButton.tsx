import React from 'react'
import { styled } from '@mui/material/styles'
import Button, { ButtonProps } from '@mui/material/Button'
import { teal } from '@mui/material/colors'

interface IButton extends ButtonProps {
  width?: string
  bgcolor?: string
  hovercolor?: string
}

const ColorButton = styled(Button)<IButton>(
  ({ theme, width, bgcolor, hovercolor }) => {
    return {
      color: theme.palette.getContrastText(teal[500]),
      width: width || '20%',
      height: 50,
      backgroundColor: bgcolor || teal[500],
      textTransform: 'none',
      '&:hover': {
        backgroundColor: hovercolor || teal[700],
      },
    }
  }
)

export default ColorButton
