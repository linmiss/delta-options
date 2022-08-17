import React, { useEffect, useState } from 'react'
import AppBar from '@mui/material/AppBar'
import Box from '@mui/material/Box'
import Toolbar from '@mui/material/Toolbar'
import IconButton from '@mui/material/IconButton'
import Typography from '@mui/material/Typography'
import Menu from '@mui/material/Menu'
import Container from '@mui/material/Container'
import Avatar from '@mui/material/Avatar'
import Button from '@mui/material/Button'
import Tooltip from '@mui/material/Tooltip'
import MenuItem from '@mui/material/MenuItem'
import HomeIcon from '@mui/icons-material/Home'
import { useHistory } from 'react-router-dom'
import { connectWallet } from '../common/ethProvider'

import Icon from '../images/android-chrome-512x512.png'

interface IPages {
  text: string
  path: string
}

const pages: IPages[] = [
  {
    text: 'Option markets',
    path: '/optionLists',
  },
  {
    text: 'Write Option',
    path: '/writeOptions',
  },
  {
    text: 'Owned options',
    path: '/ownedOptions',
  },
]

const settings = ['Disconnected']

const ResponsiveAppBar = () => {
  const [anchorElNav, setAnchorElNav] = useState<null | HTMLElement>(null)
  const [anchorElUser, setAnchorElUser] = useState<null | HTMLElement>(null)
  const [open, setOpen] = useState<boolean>(false)

  const [account, setAccount] = useState<string | null>(null)
  const [web3Modal, setWeb3Modal] = useState<any>(null)
  const [provider, setProvider] = useState<any>()
  const [signer, setSigner] = useState<any>()
  const [error, setError] = useState<any>()
  const [chainId, setChainId] = useState<number | null>(null)

  const history = useHistory()

  useEffect(() => {
    connectWallets()
  }, [])

  const connectWallets = async () => {
    try {
      const {
        web3Modal: web3ModalConnected,
        provider: providerConnected,
        accounts,
        signer: signerConnected,
        network: networkConnected,
      } = await connectWallet()
      accounts.length && setAccount(accounts[0])

      web3ModalConnected && setWeb3Modal(web3ModalConnected)
      setProvider(providerConnected)
      setSigner(signerConnected)
      setChainId(networkConnected.chainId)
    } catch (error) {
      setError(error)
    }
  }

  const handleOpenNavMenu = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorElNav(event.currentTarget)
  }
  const handleOpenUserMenu = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorElUser(event.currentTarget)
    setOpen(true)
  }

  const handleChangeItem = (path: string) => {
    history.push(path)
  }

  const handleCloseUserMenu = async () => {
    if (web3Modal) {
      await web3Modal.clearCachedProvider()
      refreshState()
    }
    setOpen(false)
  }

  const handleItemClick = async () => {
    if (web3Modal) {
      await web3Modal.clearCachedProvider()
      refreshState()
    }
    setOpen(false)
  }

  const refreshState = () => {
    setAccount(null)
    setChainId(null)
    setSigner('')
  }

  return (
    <AppBar position="static" color="primary">
      <Container maxWidth="xl">
        <Toolbar disableGutters>
          <HomeIcon sx={{ display: { xs: 'none', md: 'flex' }, mr: 1 }} />
          <Typography
            variant="h6"
            noWrap
            component="a"
            href="/"
            sx={{
              mr: 5,
              display: { xs: 'none', md: 'flex' },
              fontWeight: 700,
              letterSpacing: '.1rem',
              color: 'inherit',
              textDecoration: 'none',
            }}
          >
            DeltaOption
          </Typography>

          <Box sx={{ flexGrow: 1, display: { xs: 'none', md: 'flex' } }}>
            {pages.map(({ text, path }: IPages) => (
              <Button
                key={path}
                onClick={() => handleChangeItem(path)}
                sx={{
                  my: 2,
                  color: 'white',
                  display: 'block',
                  textTransform: 'none',
                  fontWeight: 'bold',
                }}
              >
                {text}
              </Button>
            ))}
          </Box>

          <Box sx={{ flexGrow: 0 }}>
            <Tooltip title="Open settings">
              <IconButton onClick={handleOpenUserMenu} sx={{ p: 0 }}>
                <Avatar alt="Remy Sharp" src={account ? Icon : 'C'} />
              </IconButton>
            </Tooltip>
            <Menu
              sx={{ mt: '45px' }}
              id="menu-appbar"
              anchorEl={anchorElUser}
              anchorOrigin={{
                vertical: 'top',
                horizontal: 'right',
              }}
              keepMounted
              transformOrigin={{
                vertical: 'top',
                horizontal: 'right',
              }}
              open={open}
              onClose={handleCloseUserMenu}
            >
              {settings.map((setting) => (
                <MenuItem key={setting} onClick={handleItemClick}>
                  <Typography textAlign="center">{setting}</Typography>
                </MenuItem>
              ))}
            </Menu>
          </Box>
        </Toolbar>
      </Container>
    </AppBar>
  )
}

export default ResponsiveAppBar
