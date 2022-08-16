import { createTheme } from '@mui/material/styles'

const theme = createTheme({
  palette: {
    primary: {
      // light: 这将从 palette.primary.main 中进行计算，
      main: '#5bccf6',
      // dark: 这将从 palette.primary.main 中进行计算，
      // contrastText: 这将计算与 palette.primary.main 的对比度
    },
    secondary: {
      light: 'white',
      main: '#fcde67',
      // dark: 这将从 palette.secondary.main 中进行计算，
      contrastText: '#ffcc00',
    },
    text: {
      primary: '#030e12',
      secondary: '#030e12',
    },
    // 使用 `getContrastText()` 来最大化
    // 背景和文本的对比度
    contrastThreshold: 3,

    // 使用下面的函数用于将颜色的亮度在其调色板中
    // 移动大约两个指数。
    // 例如，从红色 500（Red 500）切换到 红色 300（Red 300）或 红色 700（Red 700）。
    tonalOffset: 0.2,
  },
})

export default theme
