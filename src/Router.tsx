import React, { lazy } from 'react'
import { BrowserRouter as Router, Route, Redirect } from 'react-router-dom'

const Header = lazy(async () => await import('./Containers/Header'))
const WriteOptions = lazy(async () => await import('./Containers/WriteOptions'))
const OptionList = lazy(async () => await import('./Containers/OptionsList'))
const OwnedOptions = lazy(async () => await import('./Containers/OwnedOptions'))

function Routers() {
  return (
    <Router>
      <Route path="/" component={Header} />
      <div className="px-12 pt-4 w-5/6 h-screen mx-auto">
        <Route exact path="/writeOptions" component={WriteOptions} />
        <Route exact path="/optionLists" component={OptionList} />
        <Route exact path="/ownedOptions" component={OwnedOptions} />
      </div>

      <Redirect from="/" to="/optionLists" />
    </Router>
  )
}

export default Routers
