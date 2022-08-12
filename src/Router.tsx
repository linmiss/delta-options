import React from 'react'
import { BrowserRouter, Routes, Route, Link } from 'react-router-dom'

import Header from './Containers/Header'

function Router() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Header />}>
          <Route
            path="*"
            element={
              <main style={{ padding: '1rem' }}>
                <p>There's nothing here!</p>
              </main>
            }
          />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}

export default Router
