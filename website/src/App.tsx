import AutoAwesomeIcon from '@mui/icons-material/AutoAwesome';
import BoltIcon from '@mui/icons-material/Bolt';
import DnsIcon from '@mui/icons-material/Dns';
import DownloadIcon from '@mui/icons-material/Download';
import GitHubIcon from '@mui/icons-material/GitHub';
import LanIcon from '@mui/icons-material/Lan';
import LockIcon from '@mui/icons-material/Lock';
import PauseCircleIcon from '@mui/icons-material/PauseCircle';
import QueryStatsIcon from '@mui/icons-material/QueryStats';
import SecurityIcon from '@mui/icons-material/Security';
import SettingsSuggestIcon from '@mui/icons-material/SettingsSuggest';
import ShieldIcon from '@mui/icons-material/Shield';
import TerminalIcon from '@mui/icons-material/Terminal';
import VisibilityOffIcon from '@mui/icons-material/VisibilityOff';
import {
  AppBar,
  Box,
  Button,
  Card,
  Chip,
  Container,
  Divider,
  Grid,
  IconButton,
  Link,
  Paper,
  Stack,
  Toolbar,
  Typography,
} from '@mui/material';
import gravityWellLogo from '../../GravityWell/Assets/gravity-well.svg';

const repoUrl = 'https://github.com/zacharyreece/gravitywell';
const releaseUrl = `${repoUrl}/releases/latest`;
const brewCommand = 'brew install --cask zacharyreece/gravitywell/gravitywell';

const features = [
  {
    icon: <QueryStatsIcon />,
    title: 'Live DNS statistics',
    description: 'Track total queries, blocked queries, client count, and filtering status without opening Pi-hole.',
  },
  {
    icon: <DnsIcon />,
    title: 'Top blocked domains',
    description: 'See what your network is rejecting right now, from ad trackers to noisy telemetry endpoints.',
  },
  {
    icon: <LanIcon />,
    title: 'Top clients',
    description: 'Surface the devices generating DNS traffic, with hostname enrichment from Pi-hole and local DNS.',
  },
  {
    icon: <PauseCircleIcon />,
    title: 'Pause and resume blocking',
    description: 'Temporarily disable blocking for 5, 30, or 60 minutes, then automatically return to normal.',
  },
  {
    icon: <ShieldIcon />,
    title: 'Tailscale-friendly',
    description: 'Works with Pi-hole servers reachable over LAN, VPN, or Tailscale, including HTTPS endpoints.',
  },
  {
    icon: <VisibilityOffIcon />,
    title: 'No telemetry',
    description: 'Local-first by design. GravityWell communicates only with the Pi-hole instance you configure.',
  },
];

const privacy = [
  'No telemetry',
  'No analytics',
  'No cloud services',
  'Credentials stored in Keychain',
  'Pi-hole session IDs kept in memory',
  'Communicates only with configured services',
];

const screenshotCards = [
  {
    title: 'Dashboard',
    eyebrow: 'Live filtering overview',
    body: 'Block percentage, query counts, sparkline activity, top domains, and top clients in one compact popover.',
  },
  {
    title: 'Menu Bar',
    eyebrow: 'Signal at a glance',
    body: 'Choose block percentage, blocked query count, total queries, or icon-only mode for the status item.',
  },
  {
    title: 'Settings',
    eyebrow: 'Fast configuration',
    body: 'Enter your Pi-hole URL, save credentials to Keychain, test connectivity, and tune polling behavior.',
  },
  {
    title: 'Blocking Paused',
    eyebrow: 'Temporary bypass',
    body: 'Disable blocking when something breaks, then resume immediately or let GravityWell restore it on schedule.',
  },
];

function App() {
  return (
    <Box className="site-shell">
      <AppBar position="sticky" color="transparent" elevation={0} className="top-nav">
        <Toolbar sx={{ maxWidth: 1180, width: '100%', mx: 'auto', px: { xs: 2, md: 3 } }}>
          <Stack direction="row" spacing={1.25} sx={{ flexGrow: 1, alignItems: 'center' }}>
            <Box component="img" src={gravityWellLogo} alt="GravityWell" className="nav-logo" />
            <Typography variant="subtitle1" sx={{ fontWeight: 800, letterSpacing: '-0.03em' }}>
              GravityWell
            </Typography>
          </Stack>
          <Stack direction="row" spacing={1} sx={{ alignItems: 'center' }}>
            <Button color="inherit" href="#install" sx={{ display: { xs: 'none', sm: 'inline-flex' } }}>
              Install
            </Button>
            <IconButton href={repoUrl} target="_blank" rel="noreferrer" aria-label="Open GitHub repository">
              <GitHubIcon />
            </IconButton>
          </Stack>
        </Toolbar>
      </AppBar>

      <Container maxWidth="lg">
        <Box component="main">
          <Box component="section" className="hero-section">
            <Stack spacing={4} sx={{ alignItems: 'center', textAlign: 'center' }}>
              <Box component="img" src={gravityWellLogo} alt="GravityWell logo" className="hero-logo" />
              <Stack spacing={2.5} sx={{ alignItems: 'center' }}>
                <Chip icon={<AutoAwesomeIcon />} label="Native macOS menu bar companion for Pi-hole" className="hero-chip" />
                <Typography variant="h1">GravityWell</Typography>
                <Typography variant="h5" color="text.secondary" sx={{ maxWidth: 820, lineHeight: 1.45 }}>
                  Monitor DNS filtering, top blocked domains, top clients, and network activity directly from your
                  menu bar.
                </Typography>
                <Typography color="text.secondary" sx={{ maxWidth: 720 }}>
                  Built for homelabs, Tailscale networks, and privacy enthusiasts who want a polished local-first Pi-hole
                  companion without opening the full dashboard.
                </Typography>
              </Stack>
              <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5} sx={{ justifyContent: 'center' }}>
                <Button size="large" variant="contained" startIcon={<DownloadIcon />} href={releaseUrl}>
                  Download for macOS
                </Button>
                <Button size="large" variant="outlined" startIcon={<GitHubIcon />} href={repoUrl} target="_blank">
                  View on GitHub
                </Button>
              </Stack>
              <Paper className="terminal-pill" component="code">
                <TerminalIcon fontSize="small" />
                <span>{brewCommand}</span>
              </Paper>
            </Stack>
          </Box>

          <Box component="section" className="preview-section" id="demo">
            <ProductPreview />
          </Box>

          <Box component="section" className="section" id="features">
            <SectionHeader
              eyebrow="Features"
              title="Everything you need from Pi-hole, one click away."
              body="GravityWell focuses on the daily operational details that matter: what is blocked, which clients are noisy, and whether filtering is actually doing its job."
            />
            <Grid container spacing={2.5}>
              {features.map((feature) => (
                <Grid key={feature.title} size={{ xs: 12, md: 6, lg: 4 }}>
                  <Card className="feature-card">
                    <Box className="feature-icon">{feature.icon}</Box>
                    <Typography variant="h6" gutterBottom sx={{ fontWeight: 800 }}>
                      {feature.title}
                    </Typography>
                    <Typography color="text.secondary">{feature.description}</Typography>
                  </Card>
                </Grid>
              ))}
            </Grid>
          </Box>

          <Box component="section" className="section" id="screenshots">
            <SectionHeader
              eyebrow="Screenshots"
              title="Designed for dark mode, real networks, and quick decisions."
              body="Final release screenshots will replace these mocked launch cards once the v1.0 visual capture pass is complete."
            />
            <Grid container spacing={2.5}>
              {screenshotCards.map((card, index) => (
                <Grid key={card.title} size={{ xs: 12, md: 6 }}>
                  <ScreenshotCard {...card} index={index} />
                </Grid>
              ))}
            </Grid>
          </Box>

          <Box component="section" className="section" id="install">
            <SectionHeader
              eyebrow="Installation"
              title="Install in under a minute."
              body="No Xcode, no build-from-source instructions, no dependency hunt. Download the app or install it with Homebrew."
            />
            <Grid container spacing={2.5}>
              <Grid size={{ xs: 12, md: 6 }}>
                <Card className="install-card preferred">
                  <Chip label="Recommended" color="primary" size="small" sx={{ alignSelf: 'flex-start' }} />
                  <Typography variant="h5">Homebrew Cask</Typography>
                  <Typography color="text.secondary">
                    Best for developers, homelab operators, and anyone who already manages Mac utilities with Homebrew.
                  </Typography>
                  <Paper className="command-box" component="code">
                    {brewCommand}
                  </Paper>
                </Card>
              </Grid>
              <Grid size={{ xs: 12, md: 6 }}>
                <Card className="install-card">
                  <Chip label="Direct download" size="small" sx={{ alignSelf: 'flex-start' }} />
                  <Typography variant="h5">DMG release</Typography>
                  <Typography color="text.secondary">
                    Download the latest DMG, drag GravityWell to Applications, launch it, enter your Pi-hole URL, and
                    you are done.
                  </Typography>
                  <Button variant="outlined" startIcon={<DownloadIcon />} href={releaseUrl} sx={{ alignSelf: 'flex-start' }}>
                    Latest release
                  </Button>
                </Card>
              </Grid>
            </Grid>
          </Box>

          <Box component="section" className="section privacy-section" id="privacy">
            <Grid container spacing={4} sx={{ alignItems: 'center' }}>
              <Grid size={{ xs: 12, md: 5 }}>
                <Stack spacing={2}>
                  <Chip icon={<SecurityIcon />} label="Privacy-first" className="hero-chip" sx={{ alignSelf: 'flex-start' }} />
                  <Typography variant="h2">Local-first by default.</Typography>
                  <Typography color="text.secondary">
                    GravityWell is built for private infrastructure. It does not phone home, collect analytics, or proxy
                    your Pi-hole traffic through someone else's cloud.
                  </Typography>
                </Stack>
              </Grid>
              <Grid size={{ xs: 12, md: 7 }}>
                <Grid container spacing={1.5}>
                  {privacy.map((item) => (
                    <Grid key={item} size={{ xs: 12, sm: 6 }}>
                      <Paper className="privacy-item">
                        <LockIcon fontSize="small" />
                        <Typography>{item}</Typography>
                      </Paper>
                    </Grid>
                  ))}
                </Grid>
              </Grid>
            </Grid>
          </Box>
        </Box>
      </Container>

      <Box component="footer" className="footer">
        <Container maxWidth="lg">
          <Divider />
          <Stack
            direction={{ xs: 'column', sm: 'row' }}
            spacing={2}
            sx={{ justifyContent: 'space-between', alignItems: 'center', py: 4 }}
          >
            <Typography color="text.secondary">© 2026 GravityWell. MIT Licensed.</Typography>
            <Stack direction="row" spacing={2}>
              <Link color="inherit" href={repoUrl} target="_blank" rel="noreferrer">
                GitHub
              </Link>
              <Link color="inherit" href={`${repoUrl}/releases/latest`} target="_blank" rel="noreferrer">
                Releases
              </Link>
              <Link color="inherit" href={`${repoUrl}/security`} target="_blank" rel="noreferrer">
                Security
              </Link>
            </Stack>
          </Stack>
        </Container>
      </Box>
    </Box>
  );
}

function SectionHeader({ eyebrow, title, body }: { eyebrow: string; title: string; body: string }) {
  return (
    <Stack spacing={1.5} className="section-header">
      <Typography className="eyebrow">{eyebrow}</Typography>
      <Typography variant="h2">{title}</Typography>
      <Typography color="text.secondary" sx={{ maxWidth: 720 }}>
        {body}
      </Typography>
    </Stack>
  );
}

function ProductPreview() {
  return (
    <Paper className="product-preview">
      <Box className="menu-bar-strip">
        <Stack direction="row" spacing={1.2} sx={{ alignItems: 'center' }}>
          <span className="traffic-dot red" />
          <span className="traffic-dot yellow" />
          <span className="traffic-dot green" />
        </Stack>
        <Stack direction="row" spacing={1.5} sx={{ alignItems: 'center' }} className="menu-right">
          <Typography variant="caption" color="text.secondary">
            10:42 AM
          </Typography>
          <Chip label="35.7% blocked" size="small" color="primary" />
        </Stack>
      </Box>
      <Grid container spacing={2.5} sx={{ alignItems: 'stretch' }}>
        <Grid size={{ xs: 12, md: 5 }}>
          <Paper className="popover-card">
            <Stack spacing={2.5}>
              <Stack direction="row" sx={{ justifyContent: 'space-between', alignItems: 'center' }}>
                <Stack direction="row" spacing={1.2} sx={{ alignItems: 'center' }}>
                  <Box component="img" src={gravityWellLogo} alt="" className="mini-logo" />
                  <Box>
                    <Typography sx={{ fontWeight: 850 }}>GravityWell</Typography>
                    <Typography variant="caption" color="success.main">
                      Filtering enabled
                    </Typography>
                  </Box>
                </Stack>
                <Button size="small" variant="outlined">
                  Open Dashboard
                </Button>
              </Stack>

              <Box className="stat-orbit">
                <Box className="stat-ring">
                  <Typography variant="h3">35.7%</Typography>
                  <Typography variant="caption" color="text.secondary">
                    blocked today
                  </Typography>
                </Box>
              </Box>

              <Grid container spacing={1.5}>
                {[
                  ['84,219', 'queries'],
                  ['30,071', 'blocked'],
                  ['12', 'clients'],
                ].map(([value, label]) => (
                  <Grid key={label} size={4}>
                    <Paper className="mini-stat">
                      <Typography sx={{ fontWeight: 850 }}>{value}</Typography>
                      <Typography variant="caption" color="text.secondary">
                        {label}
                      </Typography>
                    </Paper>
                  </Grid>
                ))}
              </Grid>
            </Stack>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, md: 7 }}>
          <Paper className="activity-card">
            <Stack spacing={2.5}>
              <Stack direction={{ xs: 'column', sm: 'row' }} sx={{ justifyContent: 'space-between', gap: 1.5 }}>
                <Box>
                  <Typography variant="h5">Network activity</Typography>
                  <Typography color="text.secondary">Last hour of DNS traffic from your homelab.</Typography>
                </Box>
                <Chip icon={<BoltIcon />} label="Live polling" color="primary" />
              </Stack>
              <Box className="sparkline" aria-label="Mock DNS activity sparkline">
                {Array.from({ length: 42 }, (_, index) => (
                  <span key={index} style={{ height: `${22 + ((index * 19) % 65)}%` }} />
                ))}
              </Box>
              <Grid container spacing={2}>
                <Grid size={{ xs: 12, sm: 6 }}>
                  <MockList title="Top blocked domains" items={['googleads.g.doubleclick.net', 'app-measurement.com', 'firebaselogging-pa.googleapis.com']} />
                </Grid>
                <Grid size={{ xs: 12, sm: 6 }}>
                  <MockList title="Top clients" items={['studio-imac', 'living-room-appletv', 'office-macbook']} />
                </Grid>
              </Grid>
            </Stack>
          </Paper>
        </Grid>
      </Grid>
    </Paper>
  );
}

function MockList({ title, items }: { title: string; items: string[] }) {
  return (
    <Paper className="mock-list">
      <Typography gutterBottom sx={{ fontWeight: 850 }}>
        {title}
      </Typography>
      <Stack spacing={1}>
        {items.map((item, index) => (
          <Stack key={item} direction="row" sx={{ justifyContent: 'space-between', gap: 2 }}>
            <Typography variant="body2" color="text.secondary" noWrap>
              {item}
            </Typography>
            <Typography variant="body2" sx={{ fontWeight: 800 }}>
              {['8.2k', '5.9k', '3.1k'][index]}
            </Typography>
          </Stack>
        ))}
      </Stack>
    </Paper>
  );
}

function ScreenshotCard({ title, eyebrow, body, index }: { title: string; eyebrow: string; body: string; index: number }) {
  return (
    <Card className="screenshot-card">
      <Box className="screenshot-window">
        <Stack direction="row" spacing={0.8} className="window-dots">
          <span className="traffic-dot red" />
          <span className="traffic-dot yellow" />
          <span className="traffic-dot green" />
        </Stack>
        <Box className={`screenshot-art art-${index}`}>
          <span />
          <span />
          <span />
        </Box>
      </Box>
      <Stack spacing={1.2}>
        <Typography className="eyebrow">{eyebrow}</Typography>
        <Typography variant="h5">{title}</Typography>
        <Typography color="text.secondary">{body}</Typography>
      </Stack>
    </Card>
  );
}

export default App;
