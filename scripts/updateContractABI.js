const fs = require('fs')
const path = require('path')

fs.readFile(
  path.join(
    __dirname,
    '../contracts/artifacts/contracts/DeltaOption.sol/DeltaOption.json'
  ),
  'utf-8',
  (err, data) => {
    if (err) {
      throw err
    }

    // parse JSON object
    const user = JSON.parse(data.toString())

    fs.writeFile(
      path.join(__dirname, '../src/contracts/DeltaOption.json'),
      data.toString(),
      (error) => {
        if (error) {
          throw error
        }

        console.log('Update success!')
      }
    )
  }
)
