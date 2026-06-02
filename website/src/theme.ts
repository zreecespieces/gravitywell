import { createTheme } from '@mui/material/styles';

const fontStack = [
  'Inter',
  'ui-sans-serif',
  'system-ui',
  '-apple-system',
  'BlinkMacSystemFont',
  '"SF Pro Display"',
  '"Segoe UI"',
  'sans-serif',
].join(', ');

export const theme = createTheme({
  palette: {
    mode: 'dark',
    background: {
      default: '#050816',
      paper: 'rgba(13, 18, 36, 0.82)',
    },
    primary: {
      main: '#8ef6d6',
      light: '#bafceb',
      dark: '#38d0a8',
      contrastText: '#03130f',
    },
    secondary: {
      main: '#9bb6ff',
      light: '#c6d4ff',
      dark: '#637dcb',
    },
    success: {
      main: '#49e68f',
    },
    warning: {
      main: '#f7c76f',
    },
    text: {
      primary: '#f6f8ff',
      secondary: '#a9b4cf',
    },
    divider: 'rgba(255,255,255,0.1)',
  },
  typography: {
    fontFamily: fontStack,
    h1: {
      fontSize: 'clamp(3.2rem, 9vw, 7.2rem)',
      fontWeight: 800,
      lineHeight: 0.9,
      letterSpacing: '-0.08em',
    },
    h2: {
      fontSize: 'clamp(2.4rem, 5vw, 4.5rem)',
      fontWeight: 800,
      lineHeight: 1,
      letterSpacing: '-0.065em',
    },
    h3: {
      fontSize: 'clamp(1.8rem, 3vw, 2.8rem)',
      fontWeight: 750,
      letterSpacing: '-0.04em',
    },
    h5: {
      fontWeight: 750,
      letterSpacing: '-0.03em',
    },
    body1: {
      lineHeight: 1.75,
    },
    button: {
      textTransform: 'none',
      fontWeight: 750,
    },
  },
  shape: {
    borderRadius: 20,
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 999,
          paddingInline: 22,
          paddingBlock: 11,
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          backgroundImage: 'none',
        },
      },
    },
  },
});
